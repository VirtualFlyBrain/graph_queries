// Input: [Neuron A, Neuron B]
WITH ["VFB_0010007j","VFB_00101311"] AS neurons
 WITH neurons[0] as a, neurons[1] AS b

 MATCH (source:has_neuron_connectivity {short_form: a}), (target:Neuron {short_form: b})
 CALL gds.beta.shortestPath.yens.stream({
  nodeQuery: 'MATCH (n:Neuron) RETURN id(n) AS id',
  // min weight restriction: exists(r.weight) AND r.weight[0] >= 10
  relationshipQuery: 'MATCH (a:Neuron:has_neuron_connectivity)-[r:synapsed_to]->(b:Neuron) WHERE exists(r.weight) AND r.weight[0] >= 10 RETURN id(a) AS source, id(b) AS target, type(r) as type, 5000-r.weight[0] as weight_p',
    sourceNode: id(source),
    targetNode: id(target),
// number of paths:
    k: 1,
    relationshipWeightProperty: 'weight_p',
  relationshipTypes: ['*'],
  path: true
})
YIELD index, sourceNode, targetNode, nodeIds, path
 RETURN *
