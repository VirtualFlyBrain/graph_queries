```cypher
WITH [$neuronA$,$neuronB$] AS neurons
WITH neurons[0] as a, neurons[1] AS b
```
```cypher
MATCH (source:has_neuron_connectivity {short_form: a}), (target:Neuron {short_form: b})
CALL gds.beta.shortestPath.yens.stream({
  nodeQuery: 'MATCH (n:Neuron) RETURN id(n) AS id', 
  relationshipQuery: '
    MATCH (a:Neuron:has_neuron_connectivity)-[r:synapsed_to]->(b:Neuron) 
    WHERE exists(r.weight) AND r.weight[0] >= $WEIGHT$? 
    RETURN id(a) AS source, id(b) AS target, type(r) as type, 5000-r.weight[0] as weight_p',
  sourceNode: id(source),
  targetNode: id(target),
  k: $PATHS$,
  relationshipWeightProperty: 'weight_p',
  relationshipTypes: ['*'],
  path: true
})
YIELD index, sourceNode, targetNode, nodeIds, path"
WITH * ORDER BY index DESC"
UNWIND relationships(path) as sr"
OPTIONAL 
  MATCH cp=(x)-[:synapsed_to]-(y) 
  WHERE x=apoc.rel.startNode(sr) AND y=apoc.rel.endNode(sr) 
OPTIONAL MATCH fp=(x)-[r:synapsed_to]->(y)
RETURN 
  distinct a as root, 
  collect(distinct fp) as pp, 
  collect(distinct cp) as p, 
  collect(distinct id(r)) as fr, 
  sourceNode as source, 
  targetNode as target, 
  max(length(path)) as maxHops, 
  collect(distinct toString(id(r))+':'+toString(index)) as relationshipY 
  ```
