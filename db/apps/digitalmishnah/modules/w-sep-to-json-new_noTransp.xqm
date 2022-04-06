xquery version "3.1";

(: Hayim Lapin 8/24/18
 : Updated to improve selection of h1/h2 segments
 : better output of resultant w elements
 : Hayim Lapin 4/9/18
 : Updated to integrate into app.
 : Fixed residual issues in how tokens treated
 : Hayim Lapin 4/5/208
 : Revised again to simplify and avoid truncated lists of tokens
 : Also removes morph analysis per conversations with Raff V.
 : Hayim Lapin 3/6/2018 
 : Rewritten to copy nodes of interest to memory, to allow faster processing.
 : Hayim Lapin, 3/1/2018 
 : Adapted to be utilized as module within app
 : Hayim Lapin, 12/10/2017 
 : takes word separated data from multiple files based on their common location in Mishnah ($mCite)
 : and creates a single json file that serves as input to CollateX                                 
 : For CollateX each token has a reading surface reading "t";  
 : we provide "n" (normalized) as an alternative basis for alignent. 
 : The remaining attributes are passed through collatex. We use: 
 :    "expan" for the expanded reading of inscriptions 
 :    "wGroup" for the reading of word groups that appear as one, two, or three tokens 
 :    "resp" for identifying h1 and h2 
 :  
 : The source data is separated into <w>s, which can have children that need to be processed. 
 : Additions, deletions, and damage are marked using *Span and anchor; these can appear either as children or siblings of w. 
 : This xquery reconstructs "h1" (as written by the original files) and a nominal "h2" (incorporating any number of interventions) 
 : by using the addSpan|delSpan and corresponding anchors to identify the the added and deleted text. 
 : In addition, the xquery looks for word groups that occur as one or more tokens, but iterating through each token  
 :)

module namespace ws2j = "http://www.digitalmishnah.org/ws2j";

import module namespace config = "http://www.digitalmishnah.org/config" at "config.xqm"; 
(:  import module namespace morph = "http://www.digitalmishnah.org/morph" at "pseudoMorph.xqm"; :)
  import module namespace console="http://exist-db.org/xquery/console";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare boundary-space strip;
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace functx = "http://www.functx.com";


(: parameters need to be changed to map from templating function :)
(:declare variable $mCite as xs:string :=  request:get-parameter('mcite', '4.2.3.1');
declare variable $wits as item()* := request:get-parameter('wits', '');:)
(:declare variable $mCite as xs:string := '4.2.5.1';:)
(:declare variable $wits as item()* := 'all';:)

(:declare variable $m as item()* := if (not($mCite ='')) then $mCite else '2.3.10.3';:)

(:declare variable $witNames as xs:string* := 
   if (not($wits) or $wits = '' or $wits = 'all')
   then doc(concat($config:data-root, "/mishnah/ref.xml"))//tei:witness[@corresp]/@xml:id/string() 
   else tokenize($wits,',');:)


(::::::::::::::::::::::::::::::::::::::::::)
(:  These utility functions for revising IDs :)
declare function functx:pad-integer-to-length
  ( $integerToPad as xs:anyAtomicType? ,
    $length as xs:integer )  as xs:string {

   if ($length < string-length(string($integerToPad)))
   then error(xs:QName('functx:Integer_Longer_Than_Length'))
   else concat
         (functx:repeat-string(
            '0',$length - string-length(string($integerToPad))),
          string($integerToPad))
 } ;
declare function functx:repeat-string
  ( $stringToRepeat as xs:string? ,
    $count as xs:integer )  as xs:string {

   string-join((for $i in 1 to $count return $stringToRepeat),
                        '')
 } ;
(::::::::::::::::::::::::::::::::::::::::::)


(:  get tokenized text  :)
declare function ws2j:nodes ($mCite as xs:string, $witNames as xs:string*) as element()+ {
for $witName in $witNames
   return
      let $doc := doc(concat($config:data-root, 'mishnah/w-sep/', $witName, '-w-sep.xml')) return
         if ($doc/id(concat($witName,'.',$mCite))) then
             let $extract := (id(concat($witName, '.', $mCite), $doc))
            return
            ws2j:copy($extract/*/parent::*) (: why is this axis necessary? :)
         else ()
};

(: makes a local copy to avoid traversing the whole document for processing:)
declare function ws2j:copy($n as node()*) as node() {
   if ($n) then
   typeswitch ($n)
      case $e as element()
         return
            element {name($e)}
            {
               $e/@*,
               for $c in $e/(* | text())
               return
                  ws2j:copy($c)
            }
      default
         return
            $n
   else ()         
};


declare function ws2j:filter-w-set($w-set as node()*, $case as xs:string) as node()* {
   (: Filters w elements, selecting that contain or  those wholly within the bounding add or del span and anchor tags :)
   (: More efficient than for loop evaluating each w? :)
   (: use global variable :)
   
   let $filtered :=
   switch ($case)
      case 'comm'
         return
            for $i in distinct-values(for $a in $w-set//anchor[@type='comm']/@xml:id return string($a))
            return
               let $spans :=
               $w-set/*[contains(@spanTo, $i)] |
               $w-set//*[contains(@spanTo, $i)]/ancestor::w |
               $w-set/*[contains(@spanTo, $i)]/following-sibling::* |
               $w-set//*[contains(@spanTo, $i)]/ancestor::w/following-sibling::*
               let $anchors :=
               $w-set//anchor[@xml:id = $i]/ancestor::w/preceding-sibling::* |
               $w-set/anchor[@xml:id = $i]/preceding-sibling::* |
               $w-set//anchor[@xml:id = $i]/ancestor::w |
               $w-set/anchor[@xml:id = $i]
               
               return
                  $anchors intersect $spans
      
      case 'del'
         return
            for $i in distinct-values(for $a in $w-set//anchor[@type='del']/@xml:id return string($a))
            return
               let $spans := $w-set/*[self::delSpan][contains(@spanTo, $i)] |
               $w-set//*[self::delSpan][contains(@spanTo, $i)]/ancestor::w |
               $w-set//*[self::delSpan][contains(@spanTo, $i)]/ancestor::w/following-sibling::* |
               $w-set/*[self::delSpan][contains(@spanTo, $i)]/following-sibling::*
               
               let $anchors := $w-set/anchor[@xml:id = $i][not(ancestor::w)] |
               $w-set//anchor[@xml:id = $i]/ancestor::w |
               $w-set//anchor[@xml:id = $i]/ancestor::w/preceding-sibling::* |
               $w-set/anchor[@xml:id = $i]/preceding-sibling::*
               
               return
                  $spans intersect $anchors
      
      case 'add'
         return
         
            for $i in distinct-values(for $a in $w-set//anchor[@type='add']/@xml:id return string($a))
            return
                let $spans := $w-set/*[self::addSpan][contains(@spanTo, $i)] |
               $w-set//*[self::addSpan][contains(@spanTo, $i)]/ancestor::w |
               $w-set//*[self::addSpan][contains(@spanTo, $i)]/ancestor::w/following-sibling::* |
               $w-set/*[self::addSpan][contains(@spanTo, $i)]/following-sibling::*
               
               let $anchors := $w-set/anchor[@xml:id = $i][not(ancestor::w)] |
               $w-set//anchor[@xml:id = $i]/ancestor::w |
               $w-set//anchor[@xml:id = $i]/ancestor::w/preceding-sibling::* |
               $w-set/anchor[@xml:id = $i]/preceding-sibling::*
               
               
               return
                  $spans intersect $anchors
      default return
         ()
         
return
   $filtered 

};


declare function ws2j:regHebr($str as xs:string) as xs:string {
   (: latter borrowed from XSLT version. Better way of doing this? :)
   let $out := translate(translate(translate(replace($str, 'א$', 'ה'), 'ם', 'ן'), '|יו?', ''), '_', '')
   return
      if ($out = '') then
         translate($str, ' ', '')
      else
         translate($out, ' ', '')
};


declare function ws2j:h1h2($h1h2 as node()*, $resp as xs:string) as item()* {
   for $n in $h1h2
   return
      typeswitch ($n)
         case element(w)
            return
               <w
                  xml:id="{$n/@xml:id}"
                  resp="{$resp}">{
                     ws2j:h1h2($n/node(), $resp)
                  }</w>   
         case element(addSpan)
            return
               ()
         case element(delSpan)
            return
               ()
         case element(anchor)
            
            return
               if ($n[@type = 'add'] | $n[@type = 'del']) then
                  ()
               else
                  $n
         case element()
            return
               $n
         case text()
            return
               switch ($resp)
                  case "h1"
                     return
                        if (: $n between span/del markers :)
                        (some $s in $n/following::anchor[@type = 'add']/@xml:id
                              satisfies $n/preceding::*[contains(@spanTo, $s)]) then
                           ()
                        else if (: $n is the end of an add :)
                        ($n/following-sibling::*[1][self::anchor[@type = 'add']] 
                        and not($n/preceding-sibling::node())) then
                           ()
                        else if (: $n is the beginning of an add :)
                        ($n/preceding-sibling::*[1][self::addSpan[@type != 'comm']] 
                        and not($n/following-sibling::node())) then
                           ()
                        else
                           string-join(replace($n, '[&#xa;\s+]', ''))
                  case "h2"
                     return
                        if (: $n between span/del markers :)
                        (some $s in $n/following::anchor[@type = 'del']/@xml:id
                              satisfies $n/preceding::*[contains(@spanTo, $s)]) then
                           ()
                        else if (: $n is the end of an del :)
                        ($n/following-sibling::*[1][self::anchor[@type = 'del']] 
                        and not($n/preceding-sibling::node())) then
                           ()
                        else if (: $n is the beginning of an del :)
                        ($n/preceding-sibling::*[1][self::delSpan] 
                        and not($n/following-sibling::node())) then
                           ()
                        else
                           string-join(replace($n, '[&#xa;\s+]', ''))
                  default return
                     "error"
      default
         return
            $n

};

declare function ws2j:wdNo($str as xs:string) as xs:integer {
   (:replace($str,'[PS]\d+\.\d{1}\.\d{1,2}\.\d{1,2}\.\d{1,2}\.',''):)
   xs:integer(replace($str, '^.+\.(\d+)$', '$1'))
};


declare function ws2j:processWTokens($ab as element()+) as node()+ {
   let $add := ws2j:filter-w-set($ab, 'add')
   let $del := ws2j:filter-w-set($ab, 'del')
   let $addDel := $add union $del
   return
      for $items in $ab
      return
         (: starting with first w iterate through and group adjacent add dels:)
         let $firstH1H2 := $items/*[1]
         let $groupedAddDel := ws2j:recurseAddDel($firstH1H2, $addDel)
         (:take grouped elements and differentiate on h1/h2:)
         let $processedAddDel :=
         for $el in $groupedAddDel
         return
            if ($el/name() = 'h1h2') then
               (:process twice:)
               let $h1 := 
                  for $w in $el/*[. = $del|.[anchor[@type='add']]|.[addSpan[not(@type='comm')]]]
                  return
                     if ($w/self::w) then 
                           <w resp='h1'>{($w/@*, $w/node())}</w>
                        else
                           $w
               let $processedH1 := ws2j:h1h2($h1,'h1')
               let $h2 := 
                  for $w in $el/*[. = $add | .[anchor[@type = 'del']]|.[delSpan]]
                  return
                        if ($w/self::w) then
                           <w resp='h2'>{($w/@xml:id, $w/node())}</w>
                        else 
                           $w
               let $processedH2 := ws2j:h1h2($h2,'h2')
               return 
               ($processedH1, $processedH2)
            else
               $el
         return
            
            <ab>{
                  ($items/@*, $processedAddDel)
               }
            </ab>
      
};

(: These two functions borrow from a method for positional grouping by Michael Kay :)
(: Iterates w by w testing if should be grouped :)
declare function ws2j:recurseAddDel($w as element()?, $addDel as element()*) as element()* {
   let $next := $w/following-sibling::*[1]
   return
      if ($w) then
         if ($w = $addDel) then
            (<h1h2>{$w, ws2j:groupAddDel($w, $addDel)}</h1h2>,
            ws2j:recurseAddDel($w/following-sibling::*[not(. = $addDel)][1], $addDel))
         else
            ($w, ws2j:recurseAddDel($next, $addDel))
      else
         ()
};

(: Adds to group as necessary  :)
declare function ws2j:groupAddDel($w as element(), $addDel as element()*) as element()* {
   let $next := $w/following-sibling::*[1]
      where $next[. = $addDel]
   return
      ($next, ws2j:groupAddDel($next, $addDel))
};


declare function ws2j:w-children($wChild as node()+, $id as xs:string) as item()* {
   (: $id is not necessary --remove? :)
   for $n in $wChild
   return
      typeswitch ($n)
         case text()
            return
               if (not(normalize-space($n))) then
                  ()
               else if (some $s in $n/following::anchor[@type = 'comm']/@xml:id
                     satisfies $n/preceding::*[contains(@spanTo, $s)]) then
                     (: checking for residual comment strings that might be within w :)
                     ()
               else if ($n/parent::expan) then
                  normalize-space($n)
               else
                  string-join(normalize-space(replace($n, '[&#xa;\s+]', '')), '')
         case element(choice)
            return
               if ($n/abbr) then
                  ws2j:w-children($n/abbr/node(), $id)
               else
                  if ($n/orig) then
                     ws2j:w-children($n/orig/node(), $id)
                  else
                     ()
         case element(damageSpan)
            return
               ()
         case element(span) 
             (: necessary for case of unclear, esp reason="writ" :)
             return
               ()
         case element(gap)
            return
               ()
         case element(anchor)
            return
               if ($n/@type='add' or $n/@type='del' or $n/@type='comm') then $n
               else ()
         case element(c)
            return
               if ($n/preceding-sibling::node()[1][self::c]) then (1)
               else ()
         case element(am)
            return
               (:replace($n/text(), '\s+', ''):)
               $n/text()
               
         case element(lb)
            (: replace typographically if it appears within a word:)
            return
               text {'|'}
               
         case element()
            (: remove all other elements :)
            return
               ()
         default
            return
               ()
}
;


(: for common word groups, variously written in the witnesses get relevant token ids :)
declare function ws2j:wordGroups($wElems as element()*) {
   for $w in $wElems
   (: identify the text of this w as well as 1, 2, [3] following :)
   let $this :=
   if ($w/expan) then
      $w/expan
   else
      if ($w/reg) then
         $w/reg/text()
      else
         $w/node()
   let $thisPlus1 := if ($w/following-sibling::w[1]/expan) then
      $w/following-sibling::w[1]/expan
   else
      if ($w/following-sibling::w[1]/reg) then
         $w/following-sibling::w[1]/reg
      else
         $w/following-sibling::w[1]/node()
   let $thisPlus2 :=
   if ($w/following-sibling::w[2]/expan) then
      $w/following-sibling::w[2]/expan
   else
      if ($w/following-sibling::w[2]/reg) then
         $w/following-sibling::w[2]/reg
      else
         $w/following-sibling::w[2]/node()
         (:  :)
   let $joined2 := normalize-space(string-join($this | $thisPlus1))
   let $joinedOut2 := normalize-space(string-join($this | $thisPlus1, '_'))
   let $joined3 := normalize-space(string-join($this | $thisPlus1 | $thisPlus2))
   let $joinedOut3 := normalize-space(string-join($this | $thisPlus1 | $thisPlus2, '_'))
   
   return
      (: shel :)
      if (matches(string-join($w/node()), '^ו?של$'))
      then
         (<keep
            
            xml:id="{$w/@xml:id}">{$joinedOut2}</keep>,
         <omit
            
            xml:id="{$w/following-sibling::w[1]/@xml:id}"/>)
         (: ezehu :)
         (: why is the first condition even necessary? :)
         (: For single word rendering was matched by $joined2; should have been ignored:)
      else
         if (matches($this, '^.?אי?ז[הו]{1,2}[וי]א?$'))
         then
            ()
         else
            if (matches($joined2, '^.?אי?ז[הו]{1,2}[וי]א?$'))
            then
               (<keep
                  
                  xml:id="{$w/@xml:id}">{$joinedOut2}</keep>,
               <omit
                  
                  xml:id="{$w/following-sibling::w[1]/@xml:id}"/>)
            else
               if (matches($joined3, '^.?אי?ז[הו]{1,2}[וי]א?$'))
               then
                  (<keep
                     
                     xml:id="{$w/@xml:id}">{$joinedOut3}</keep>,
                  <omit
                     
                     xml:id="{$w/following-sibling::w[1]/@xml:id}"/>,
                  <omit
                     
                     xml:id="{$w/following-sibling::w[2]/@xml:id}"/>)
               else
                  if (matches($joined2, '^כא?יצד$|^כא?יזהצד$'))
                  then
                     (<keep
                        
                        xml:id="{$w/@xml:id}">{$joinedOut2}</keep>,
                     <omit
                        
                        xml:id="{$w/following-sibling::w[1]/@xml:id}"/>)
                  else
                     if (matches($joined3, '^כא?יצד$|^כא?יזהצד$'))
                     then
                        (<keep
                           
                           xml:id="{$w/@xml:id}">{$joinedOut3}</keep>,
                        <omit
                           
                           xml:id="{$w/following-sibling::w[1]/@xml:id}"/>,
                        <omit
                           
                           xml:id="{$w/following-sibling::w[2]/@xml:id}"/>
                        )
                     else
                        if (matches($joined2, '^ו?לפי?כך$'))
                        then
                           (<keep
                              
                              xml:id="{$w/@xml:id}">{normalize-space(string-join($this | $thisPlus1, '_'))}</keep>,
                           <omit
                              
                              xml:id="{$w/following-sibling::w[1]/@xml:id}"/>)
                        else
                           ()
};



declare function ws2j:splitToken($w as element()) as item()* {
   let $idStub := replace($w/@xml:id,'\d+$','')
   let $abNum := xs:integer(tokenize($w/@xml:id,'\.')[last()])
   let $t := tokenize($w,'\*')
   let $num := count($t)
   return 
      
      for $n in 1 to $num 
      return <w>{
         ($w/@resp, attribute xml:id {
            concat($idStub,functx:pad-integer-to-length($abNum + (($n - 1) * 10),5))
         },$t[$n])
      }</w>
};

declare function ws2j:fixIDsInTokenList($wSequence as element()+) as element()+ {
   (: reassigns IDs for tokens needing special handling :)
   for $ab in $wSequence 
      return <ab xml:id="{$ab/@xml:id}">{
      for $w in $ab/* 
      return
         (: tried with switch statement and kept getting errors. reverted to concatenated if-else :)
         if ($w[self::w[contains(.,'*')]]) then ws2j:splitToken($w)
         else $w
    }</ab>
    
};
declare function ws2j:buildJSON($wSequence as element()+) as map(*){
   map{ 
   (:  could paramterize settings :)
   "joined" : false(),
   "witnesses" : for $ab in $wSequence
     
     return
         let $pref := 
         (:adapts functx:index-of-node:) 
         (:is this better than using index-of?:)
            for $seq in (1 to count($wSequence))
            return 
            $seq[$wSequence[$seq] is $ab]
            
         return   
         (
         map { "id" : concat(string(format-number($pref,"000")),'-',substring-before($ab/@xml:id,'.')), 
         "tokens" : array {

         let $wGroups := ws2j:wordGroups($ab//w)
         
             return 
             
                for $w in $ab/w[normalize-space()]
                let $tText:= string-join(ws2j:w-children($w/node(), $ab/@xml:id/string()),'')
                let $rText := array {
                   if ($w/@xml:id = $wGroups[self::keep]/@xml:id) then 
                      string($wGroups[self::keep][@xml:id = $w/@xml:id])
                   else if ($w/@xml:id = $wGroups[self::omit]/@xml:id) then 
                      '--'
                   else if ($w/*/expan) then
                      tokenize($w/*/expan/text(), '\s+')
                   else if ($w/*/reg) then
                      $w/*/reg
                   else
                      $tText }         
                return (
                   if (string($tText)) then 
                   (let $tMap:=
                   (: want to make sure we avoid possible empty n values:)
                   (: if n would otherwise be empty we use the first character of t :)
                   (: also want to add suffix -h1 or -h2 to ids in order to disambiguate:)
                      map {"t":  $tText ,
                         "n" :  if (normalize-space(ws2j:regHebr($rText?1))) then ws2j:regHebr($rText?1) else substring($tText,1,1),
                         "id" : if ($w/self::w/@resp) then concat($w/@xml:id/string(),'-',$w/@resp/string()) else $w/@xml:id/string()} 
                   let $respMap:= 
                      if ($w/self::w/@resp) then
                         map {"resp": $w/@resp/string()}
                      else ()
                   let $expMap:= 
                      if ($w/*/expan) then 
                         map {"expan" : string-join($w/*/expan/text(),' ')} 
                      else () 
                   let $wGrpMap:= if ($w/@xml:id = $wGroups[self::keep]/@xml:id) then 
                      map {"wGrp" : $rText?1}
                   else 
                      ()
                   return 
                   let $tokens:= if (contains($wGrpMap?wGrp,'_')) then $wGrpMap?wGrp else $tMap?t
                   let $expans:= if ($expMap?expan) then $expMap?expan else ''
                   return
                      map:merge(($tMap, 
                         $respMap, 
                         $expMap, 
                         $wGrpMap
                         (:,
                         if (not($rText = '--')) 
                            then
                            (\: get pseudomorphological analysis of tokens and expans; j = json output, x = xml output :\)
                            morph:pseudoMorph($tokens,$expans,"j") 
                         else ():)
                         )),
                      if (array:size($rText) > 1)
                         then
                            for $i in 2 to array:size($rText)
                            return
                            map{ "t" : "--",
                               "n" : ws2j:regHebr($rText($i)),
                               "id" : concat($w/@xml:id, '-', string($i))}
                      else
                            () ) else ()
             )   
                      }})}
};

declare function ws2j:witnessList ($mcite,$wits) {
   doc(concat($config:data-root, "/mishnah/index-m.xml"))//tei:ab[contains(@xml:id,$mcite)]/tei:ptr/@n/string()
};


declare function ws2j:getTokenData($mcite as xs:string, $wits as xs:string*) {
   (: get only ws and string that are not between comm span and anchor:)
   (: instead do this after? :)
   (: get nodes :)
   let $out := 
      let $m := if (not($mcite) or $mcite = '') then '1.1.1.1' else $mcite
      let $witNames  as xs:string* :=
         if (count($wits) > 1) then $wits
         else if (not($wits) or $wits = '' or $wits = 'all') 
            then 
            doc(concat($config:data-root, "/mishnah/index-m.xml"))//tei:ab[@xml:id = concat('index-m.',$m)]/tei:ptr/@n/string() 
         else tokenize($wits,',')
      let $nodes := ws2j:nodes($m, $witNames)
      let $noComm := for $ab in $nodes
      return
         (console:log(string-join($witNames,',')),
         <ab
            xml:id="{$ab/@xml:id}">{
               $ab/* except ws2j:filter-w-set($ab, 'comm')
            }</ab>
            )
      (:simplifiy list, removing elements not required for alignment:)
      
      (: get list of tokens with separation of add/del into h1/h2 :)
      let $listOfTokens :=
         for $srcTokens in $noComm
         return
            ws2j:processWTokens($srcTokens)
      return
      let $revListOfTokens := ws2j:fixIDsInTokenList($listOfTokens) return
         ws2j:buildJSON($revListOfTokens)
         (: Needed
      to do cleanup in second pass bec XQ does not nec know preceding or following id :)
      (: Should be fixed.:)
   return
      
      serialize($out, 
        <output:serialization-parameters>
            <output:method>json</output:method>
        </output:serialization-parameters>)      
(:$out:)
};


