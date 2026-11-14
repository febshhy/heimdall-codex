# Pure boundary decisions for the ten-section Graph Protocol. Schema 3 only.
def text: type=="string" and (contains("\u0000")|not) and (gsub("[[:space:]]"; "")|length>0);
def output_name: type=="string" and test("^[A-Za-z_][A-Za-z0-9_-]*$");
def distinct: length == (unique|length);
def strings: type=="array" and all(.[]; text);
def strset: strings and distinct;
def named: strset and length>0;
def only($fields): (keys_unsorted-$fields)==[];
def nid: type=="string" and test("^N[1-9][0-9]*$");
def dag($nodes;$edges):
  ($nodes|map(.id)) as $ids |
  (reduce $edges[] as $e ({}; .[$e.to]=((.[$e.to]//0)+1))) as $indegree |
  (reduce $edges[] as $e ({}; .[$e.from]=((.[$e.from]//[])+[$e.to]))) as $out |
  def walk($queue;$degrees;$seen):
    if ($queue|length)==0 then $seen==($ids|length)
    else
      $queue[0] as $current |
      (reduce ($out[$current]//[])[] as $next
        ({degree:$degrees,queue:$queue[1:]};
         .degree[$next] -= 1 |
         if .degree[$next]==0 then .queue += [$next] else . end)) as $step |
      walk($step.queue;$step.degree;$seen+1)
    end;
  walk([$ids[] | select(($indegree[.]//0)==0)];$indegree;0);
def valid_a($domain):
  . as $a |
  (type=="object" and only(["nodes","edges"])) and
  ($a.nodes|type=="array" and length>0) and ($a.edges|type=="array") and
  (all($a.nodes[]; type=="object" and only(["id","domain","inputs","outputs"]) and (.id|text) and (.domain==$domain) and (.inputs|strset) and (.outputs|strset))) and
  ($a.nodes|map(.id)|distinct) and
  (all($a.edges[]; . as $edge |
     (type=="object" and only(["from","to","data"])) and (.from|text) and (.to|text) and (.data|text) and
     ($edge.from != $edge.to) and
     (any($a.nodes[]; .id==$edge.from and (.outputs|index($edge.data)!=null))) and
     (any($a.nodes[]; .id==$edge.to and (.inputs|index($edge.data)!=null))))) and
  ($a.edges|distinct) and (dag($a.nodes;$a.edges));
def valid_e($a):
  type=="array" and length>0 and distinct and
  (all(.[]; . as $b |
    type=="object" and only(["at","kind","mitigation"]) and
    (.at|text) and (.mitigation|text) and (.kind|IN("wrong_context","missing_input","misinterpretation")) and
    any($a.nodes[];.id==$b.at))) and
  (map([.at,.kind])|distinct);
def valid_r:
  type=="object" and only(["method","why","verification","inputs"]) and
  (.method|text) and (.why|text) and (.inputs|named) and
  (.verification|type=="array" and length>0 and all(.[]; strings and length>0));
def valid_subgraph($domain):
  type=="object" and only(["A","E","R"]) and
  (.A|valid_a($domain)) and (.A as $a|.E|valid_e($a)) and (.R|valid_r);
def valid_path:
  type=="string" and length>0 and
  (startswith("/")|not) and (startswith("~")|not) and
  (contains("\\")|not) and (contains("//")|not) and (contains("\u0000")|not) and
  (split("/")|all(.[]; .!="." and .!="..")) and
  ((endswith("/")|not) or length>1);
def valid_node:
  . as $n |
  type=="object" and only(["id","domain","owner","mode","task","depends_on","requires","produces","write_set","verifies","gate","proof_gate","delegation"]) and
  (.id|nid) and (.domain|text) and (.owner|text) and (.task|text) and
  (.mode|IN("WRITE","RUN","READ")) and (.gate|IN("none","review","proof")) and
  (.depends_on|strset and all(.[]; nid)) and (.produces|named and all(.[];output_name)) and
  (.write_set|type=="array" and distinct and all(.[]; valid_path)) and
  (.verifies|strset and all(.[]; nid)) and
  (.requires|type=="array" and distinct and all(.[];
    type=="object" and only(["from","output"]) and (.from|nid) and (.output|output_name))) and
  (if $n.mode=="WRITE" then ($n.write_set|length>0) and $n.gate=="none" and ($n.verifies|length==0)
   else ($n.write_set|length==0) end) and
  (($n.gate=="none") == ($n.verifies|length==0)) and
  (if $n.gate=="proof" then $n.mode=="RUN" else true end) and
  (if has("proof_gate") then (.proof_gate|nid) else true end) and
  (.delegation|valid_subgraph($n.domain));
def valid_plan:
  . as $p |
  type=="object" and only(["schema_version","planned_nodes","plan_sha256","repository_id"]) and
  (.schema_version|type=="number" and .==3) and
  (.planned_nodes|type=="array" and length>0 and all(.[];valid_node) and (map(.id)|distinct)) and
  (all($p.planned_nodes[]; . as $n |
    all($n.depends_on[]; . as $d | ($d!=$n.id) and any($p.planned_nodes[]; .id==$d)) and
    all($n.requires[]; . as $r |
      ($n.depends_on|index($r.from)!=null) and
      any($p.planned_nodes[]; .id==$r.from and (.produces|index($r.output)!=null)) and
      ($n.delegation.R.inputs|index($r.from+"."+$r.output)!=null)) and
    all($n.depends_on[]; . as $d | any($n.requires[];.from==$d)) and
    all($n.verifies[]; . as $v |
      ($n.depends_on|index($v)!=null) and
      any($p.planned_nodes[]; .id==$v and .mode=="WRITE" and .owner!=$n.owner and .domain!=$n.domain)) and
    (if $n.mode=="WRITE" then any($p.planned_nodes[]; .gate=="review" and (.verifies|index($n.id)!=null)) else true end) and
    (if ($n|has("proof_gate")) then
      ($n.mode=="WRITE") and ($n.depends_on|index($n.proof_gate)!=null) and
      any($p.planned_nodes[];.id==$n.proof_gate and .gate=="proof")
     else true end))) and
  (dag($p.planned_nodes; [$p.planned_nodes[] as $n | $n.depends_on[]|{from:.,to:$n.id}]));
def canon:
  .A.nodes |= (map(.inputs|=sort | .outputs|=sort)|sort_by(.id)) |
  .A.edges |= sort_by(.from,.to,.data) |
  .E |= sort_by(.at,.kind,.mitigation) |
  .R.inputs |= sort;
def valid_return($t):
  type=="object" and only(["node_id","implemented","outputs","summary"]) and
  (.node_id==$t.id) and (.summary|text) and
  (.implemented|valid_subgraph($t.domain)) and
  ((.implemented|canon)==($t.delegation|canon)) and
  (.outputs|type=="object" and ((keys|sort)==($t.produces|sort)) and all(.[];text));
