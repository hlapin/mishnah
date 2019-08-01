xquery version "1.0";

import module namespace config="http://www.digitalmishnah.org/config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0"; 

let $ch:= request:get-parameter('ch', '')

let $input := doc(concat($config:data-root, "/tosefta/ref-t.xml"))

let $div3 := $input//tei:div3/id(concat('ref-t.',$ch))

return
    element {fn:QName("http://www.tei-c.org/ns/1.0", "div3")} {
        attribute n {concat($div3/ancestor::tei:div2/@n/data(), ' ', replace($div3/@xml:id/data(), '^.*?\.(\d+)$', '$1'))},
        $div3/@*,
        $div3/node()
    }