xquery version "3.1";


import module namespace config = "http://www.digitalmishnah.org/config" at "config.xqm";  

(:import module namespace console="http://exist-db.org/xquery/console";:)

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace cmp = "http://www.digitalmishnah.org/tbl";


declare boundary-space strip;
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html5";
declare option output:media-type "text/html";



(:declare variable $data-root := "file:///c:/users/hlapin/documents/digitalmishnah-tei";:)
declare variable $mcite := "4.2.5.1";
declare variable $wits := "S08010,S07326,S00483,S01520,S00651,S08174,P00001,P179204,S07319,S08010,P00002,S07204,S07106,S07394,S07397";


declare function cmp:w-to-span ($wParts as node()+,$h as xs:string*) as item()*{
   typeswitch ($wParts)
   case text() 
      return cmp:doText($wParts, $h)
   case element (tei:w) return   
      if ($wParts/tei:choice) then 
         cmp:filter($wParts/node(), $h)
      else 
         <span>{
            attribute class {'surface'},
            attribute id {
               (concat($wParts/@xml:id,
               if ($h) then concat('-',$h) else ()))},
            (: conditions based on $h and presense of span/del :)
            if ($h = 'h2' 
                and not($wParts//(tei:addSpan[@type='add']|tei:delSpan|tei:anchor[@type='add']|tei:anchor[@type='del']))) 
            then <span class="add">{cmp:filter($wParts/node(), $h)}</span>
            else cmp:filter($wParts/node(), $h)
            }</span> 
   case element (tei:choice) return 
      <span>{ attribute class {'choice'},cmp:filter($wParts/node(), $h)}</span>
   case element (tei:orig) | element (tei:abbr)  return
      <span >{
         attribute class {'surface', $wParts/name()},
         attribute id {concat($wParts/ancestor::tei:w/@xml:id/string(),if ($h) then concat('-',$h) else ())},
         (: conditions based on $h and presense of span/del :)
         if ($h = 'h2' 
                and not($wParts//(tei:addSpan[@type='add']|tei:delSpan|tei:anchor[@type='add']|tei:anchor[@type='del']))) 
            then <span class="add">{cmp:filter($wParts/node(), $h)}</span>
            else cmp:filter($wParts/node(), $h)
            }</span> 
   case element(tei:expan) return
      <span class="expan">{cmp:filter($wParts/node(),$h)}</span>   
   case element (tei:anchor) | element(tei:addSpan) | element(tei:delSpan) | element(tei:damageSpan)| element (tei:reg)
      return ''   
   case element(tei:am) | element (tei:c)
      return cmp:filter($wParts/node(), $h)
   default return ()   
 };

declare function cmp:filter ($in as item()+, $h as xs:string*) as item()* {
   for $out in $in return cmp:w-to-span($out,$h)
};

(:This is an attempt to display tokens with internal adds and dels as whole words :)
(: not sure this is necessary for display, or even desirable :)
declare function cmp:doText($txtNode as node(), $h as xs:string*) as item()+ {
   let $addDel as xs:string* := 
             let $addSpan := $txtNode/preceding-sibling::tei:addSpan[1][@type='add']
             let $addAnchor := $txtNode/following-sibling::tei:anchor[1][@type='add']
             let $delSpan := $txtNode/preceding-sibling::tei:delSpan[1]
             let $delAnchor := $txtNode/following-sibling::tei:anchor[1][@type='del']
             return 
               if ($addAnchor[@xml:id = substring-after($addSpan/@spanTo,"#")])
               then 'add'
               else if (($addAnchor and not(exists($addSpan))) or($addSpan and not(exists($addAnchor))))
               then 'add' 
               else if ($delAnchor[@xml:id = substring-after($delSpan/@spanTo,"#")])
               then 'del'
               else if (($delAnchor and not(exists($delSpan))) or($delSpan and not(exists($delAnchor))))
               then 'del' 
               else ()
    let $dam as xs:string* := 
             let $damageSpan := $txtNode/preceding-sibling::tei:damageSpan[1]
             let $damageAnchor := $txtNode/following-sibling::tei:anchor[1][@type='damage']
             return 
               if ($damageAnchor[@xml:id = substring-after($damageSpan/@spanTo,"#")])
               then 'damage'
               else if (($damageAnchor and not(exists($damageSpan))) or($damageSpan and not(exists($damageAnchor))))
               then 'damage' 
               else ()
   return 
   if (not(normalize-space($txtNode))) then 
    ''
   else if ($h = 'h2') then
      if ($addDel = 'add') then <span>{attribute class {$addDel, $dam},normalize-space($txtNode)}</span>
      else if ($addDel = 'del') then <span>{attribute class {$addDel, $dam},normalize-space($txtNode)}</span>
      else if ($dam = 'damage') then <span>{attribute class {$dam},normalize-space($txtNode)}</span>
      else normalize-space($txtNode)
   else if ($h='h1') then
      if ($addDel = 'add') then ''
      else if ($addDel = 'del' and not($dam = 'damage')) then normalize-space($txtNode)
      else if ($dam = 'damage') then <span>{attribute class {$dam},normalize-space($txtNode)}</span>
      else normalize-space($txtNode)
   else if ($dam = 'damage') then <span>{attribute class {$dam},normalize-space($txtNode)}</span>
   else normalize-space($txtNode)
  };

declare function cmp:align-table($mcite as xs:string, $wits as xs:string) as element()+{
let $apps := doc(concat($config:data-root,'mishnah/collations/',$mcite,'.xml'))//tei:ab
let $data := for $wit in tokenize($wits,',') return
   doc(concat($config:data-root,'mishnah/w-sep/',$wit,'-w-sep.xml'))/id(concat($wit,'.',$mcite))
   return
let $cols := $apps//tei:app
(: each tei:app is a variation locus :)
let $rows := tokenize($wits,',')
(: source is organized by locus, with readings for each witness grouped by similarity,
 : we want to pivot the data to yield a table with row for each witness. :)
return 
   for $row in $rows return
      <tr>{
      for $col in $cols return
        (: each rdg is a cell in table :)
         <td>{
             (:let $currRdg := $col//tei:ptr[contains(@target,$row)]:)
             let $currRdg := for $ptr in $col//tei:ptr return if (contains($ptr/@target, $row)) then $ptr else ()
             let $grp := $currRdg/ancestor::tei:rdgGrp/@n
            return
               (
                if (not($grp)) then ()else attribute class {concat('group-',$grp)},   
               for $wdId in $currRdg/@target
               return 
                  let $idParts := tokenize($wdId,'-') return
                  
                     let $w := $data/id(substring-after ($idParts[1],'#'))
                     return (
                        cmp:filter($w,$idParts[2])
                        )
                )
          }</td>
      }</tr>
      
 };
<table>{cmp:align-table($mcite, $wits)}</table>