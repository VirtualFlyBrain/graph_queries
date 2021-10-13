# Circuit Browser Query (Shortest Weighted Path Algorithm)

Geppetto passes a list of neuron IDs (short_form). 

---
**NOTE**

Curretly Geppetto is configured to limit this list to 2 but there is future potential for 'via' neurons. 

---

```cypher
WITH [$neuronA$,$neuronB$] AS neurons
WITH neurons[0] as a, neurons[1] AS b
```

From this we take just the first as the source and 2nd as the target for path searching.

```cypher
MATCH (source:Neuron:has_neuron_connectivity {short_form: a}), (target:Neuron:has_neuron_connectivity {short_form: b})
```

Using the stream (creating the graph at runtime), [Yen’s k-Shortest Path algorithm](https://neo4j.com/docs/graph-data-science/current/algorithms/yens/): 

Firstly take all nodes with :Neuron:has_neuron_connectivity labels exist then create a graph where forward synapsed_to edge relationships have a weight >= the user given minimum weight. We at this point generate the inverted weight value (5000-weight = weight_p) as the algorithm looks for the lowest value and we need max weight prioritised. 

---
**NOTE**

5000 was chosen as a value larger than the max weight value curretly available. This will need to be reviewed and optimised in respect of hops vs weight. 

---

```cypher
CALL gds.beta.shortestPath.yens.stream({
  nodeQuery: 'MATCH (n:Neuron:has_neuron_connectivity) RETURN id(n) AS id', 
  relationshipQuery: '
    MATCH (a:Neuron:has_neuron_connectivity)-[r:synapsed_to]->(b:Neuron:has_neuron_connectivity) 
    WHERE exists(r.weight) AND r.weight[0] >= $WEIGHT$? 
    RETURN id(a) AS source, id(b) AS target, type(r) as type, 5000-r.weight[0] as weight_p',
```

    Then the algorithm takes in the source and target node ids and the number of paths (k) the user selected with the slider. The weighting is done using the 'weight_p' value created in our custon graph above. All relationships are explored as we already filterted this in our created graph. 
    
```cypher
  sourceNode: id(source),
  targetNode: id(target),
  k: $PATHS$,
  relationshipWeightProperty: 'weight_p',
  relationshipTypes: ['*'],
  path: true
})
YIELD index, sourceNode, targetNode, nodeIds, path
```

From the shortest path algorithm we get a list of paths 0-N (index), source/target Node are the one we passed in, nodeIds is a list of node ids for each neuron along the found path (these id's match real neuron nodes) and the path is the complete path or real neuron nodes and virtual relationships (don't actually exist in PDB).
As we only have the forward relationship plus only the virtual 'path_N' edges we temp created rather than the real 'symapsed_to' edges we first derive them by finding all synaped_to edges between each relationship hop (Complete Path - cp) in the path by unwinding them. We then just extract the forward paths for the same neuron hops (Forward Path - fp) so Gepptto knows which way to draw the path/edge arrows.

```cypher
WITH * ORDER BY index DESC
UNWIND relationships(path) as sr
OPTIONAL 
  MATCH cp=(x)-[:synapsed_to]-(y) 
  WHERE x=apoc.rel.startNode(sr) AND y=apoc.rel.endNode(sr) 
OPTIONAL MATCH fp=(x)-[r:synapsed_to]->(y)
```

```cypher
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

Geppetto is passed all distinct Primary Paths (pp), complete Paths (p), all forward edge ids so the arrows can be drawn for them and weight shown correctly, source/target nodes and for the graph layout the max number of hops (longest path) value is passed along with a list of the edge ids with their respective path index so they can be positioned in path levels (X axis).
