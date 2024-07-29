The autotech module has several main goals. The first two are shared with the old autotech, the last ones are new:
- adapt the tech tree so if you research a tech, you will be able to use all the recipes from that tech right away.
- change the research costs to slowly ramp up as you get further in the tech tree.
- report all unreachable items/recipes/techs, and in particular whether the victory tech is reachable.
- enforce that if a tech dependency of a tech has a particular science pack in its costs, then that tech will have at least the same science packs (monotonicity of science pack costs, as checked by the python tests).
- report as much useful information as possible to help development. Do cheap checks for errors early. Have an option to turn on verbose logging to debug more complicated issues.
- allow the code to be run in a unit test scenario on a dumped version of the Factorio data, to help development and allow automated testing
- support more advanced Py features, like inter-surface logistics, differing tech trees based on a starting scenario, optional side techs, etc

There are two versions of this explanation. The first gives all the details including a rationale but assumes a computer science background, the second only assumes you know what a directed graph is and is mainly tailored to users of autotech.

== Explanation assuming a computer science background ==

The second point, changing the tech costs, is fairly easy, so let's get it out of the way first. The first phase results in a tech tree with a linear ordering. We can use this linear ordering to find the longest path from every science pack to every tech as follows. For every science pack, loop over the techs in this linear order, and then find the longest distance by taking the highest longest distance of all its dependencies plus one (zero if it's the source, infinity if it's not the source and has no dependencies or if it doesn't have the science pack as a cost). For every tech we can then compute the tech costs by taking these longest distances for the science packs it costs and inputting those into the science cost formula. This generalises the old autotech code where there was a linear ordering between science packs (automation, p1, logi, p2, etc). This generalisation allows for new side science packs such as the energy science pack.

My proposal for a tech cost formula is to scale the overall tech cost with the smallest longest distance among the science packs. Furthermore, the individual pack count can be chosen by taking the longest distances from smallest to largest, and then assigning a pack count to each, higher counts for the farther away science packs. This will probably need some tweaking in practice.

The first point, adapting the tech tree, is tricky, hence this README. Let's first list the phases of autotech, and then explain the steps one by one:
1 construct recipe graph
2 linearise the recipe graph, ignoring cycles
  2a canonise all choices along the way, report these choices
  2b error if victory tech unreachable from starting tech
  2c report but don't error if other things are unreachable or if a choice cannot be made due to cycles
  2d report but don't error on cycles found in this graph
3 construct true tech dependency graph from unlinearised but canonised recipe graph
4 linearise resulting tech graph, error out on cycle and report it
5 compute transitive reduction of unlinearised true tech dependency graph
6 attach tech costs to techs
7 edit Factorio tech dependencies to match unlinearised reduced true tech dependency graph and match new tech costs

A cache file can replace all these steps. Note that cache files may now remove dependencies due to the transitive reduction, which the old autotech did not do. We can leave a setting to allow (modified versions of) steps 4, 5 and 6 to be executed despite a cache file being used for those that want autotech to affect other mods.

The 'recipe graph' is a graph where the nodes are Factorio concepts, such as items, recipes, fluids, recipe categories, etc, and the edges are Factorio dependencies between these. For example, the node 'iron plate' may have an edge 'is crafted by' to the node 'iron plate smelting'. (yes, this means the name 'recipe graph' is incorrect, as it contains things that are not recipes too.) We generate this graph in two phases: we first create all the nodes, and then we create all the edges. The reason for the two phases is that during the edge phase we know all nodes already exist and we can just look them up by name, so we don't need to worry about the order we generate the nodes or edges in.

There is one major complication however. We often have several ways to get something, for example, there could be several recipes to make an item. This means we have to make this recipe graph a 'disjunctive graph'. In such a graph, an edge from node A has multiple targets B_i, instead of just one target B like in a normal graph, representing that node A needs at least one of the B_i nodes. For example, the Ralesia item requires one or more of its recipes to be unlocked (one edge, several targets), as well as the crafting category (one edge, one target), so it has at least these two edges. More formally, every node depends on a conjunction of a disjunction of targets (an AND with OR arguments), which is sort of equivalent to a conjunctive normal form. Indeed, this makes a disjunctive graph effectively a monotone boolean circuit with unbounded fan-in and fan-out (only OR and AND gates, no NOT gates). (don't worry if you don't know what these are)

Let's now define the 'true tech dependency graph' as the graph where the nodes are the techs, and the edges are the 'true' dependencies between the techs, that is, the dependencies according to the recipe graph. For example, if tech A gives a building that requires the item Intermetallics, then it has a 'true dependency' on the tech that gives you the recipe to make Intermetallics. We also include the already existing tech dependencies and science pack requirements in this graph. This essentially comes down to doing a reachability query for every tech on the recipe graph.

It's tempting to now try to compute this true tech dependency graph directly from the recipe graph. Unfortunately, there are two major problems, which both stem from the fact that this computed true tech graph will also be a disjunctive graph. First, turning a monotone boolean circuit into a conjunctive normal form (which is basically what we're trying to do) involves exponential blowup of the formula size (it's NP-hard). In other words, your true tech graph may be exponentially larger than the recipe graph. You'd have to add a bunch of heuristics to try and stop the exponential blowup for practical examples, but that's a lot of complicated code that will not necessarily work, and it's going to be slow whatever you do.

Second, there's a fundamental problem with this true tech graph: Factorio does not allow disjunctive dependencies between techs. This means we'll have to make a choice for every edge no matter how we go about it, and just computing the disjunctive true tech dependency graph does not help us solve this problem at all. Luckily, this second problem also shows us the path how to resolve both problems.

Since we have to make a choice at some point anyway, why not make our choice in the recipe graph already? We can just linearise the recipe graph, and for every disjunctive edge, choose the target that's the earliest in the linear ordering. We'll call this 'canonising' of the graph, where we choose a 'canon' target for every disjunctive edge. With this canonisation, our disjunctive recipe graph turns into a normal graph, so computing a normal true tech dependency graph out of this is straightforward using for example BFS. Note that this solution is not perfect: since there are several possible linearisations, it's possible we choose a linearisation that leads to a canonicalisation that leads to a cycle in the true tech dependency graph while a different linearisation would have led to no cycle in the tech dependency graph. This is what the old autotech also did, and I expect this to not be a problem in practice. Worst case, we can add a mechanism to force a specific canonicalisation.

With that, the major problem is out of the way, and all that remains are implementation details. Note that 'report' and 'log' are different in that there's different settings to turn on either one, and that 'report's indicates something is potentially wrong.

Step 1: the code will log the entire recipe graph, to make it clear how it interpreted the code. Two details about the recipe graph: we'll need a file with 'scripted dependencies' like guano, and we'll need to respect the flag we have for e.g. soot sorting that should not lead to seeing soot as a source of silver.

Step 2: we apply the standard Kahn's algorithm for linearisation, which can be adapted easily for disjunctive graphs, see here: https://math.stackexchange.com/q/2449379. We linearise as much as possible and leave any cycles in the graph for later steps. We log the entire linear ordering.

Step 2a: we partially canonise the choices due to the partial linear ordering from earlier. All choices are logged.

Step 2b: we do a BFS from the starting node which only uses linearised nodes, and see if the victory tech is reachable. This step comes early to aid the development process and error out as early as possible.

Step 2c: we can use the BFS from 2b to see what nodes are not reachable and report those. We can also report all the edges that did not get a canon target.

Step 2d: We can report a cycle with the standard cycle reporting algorithm: start in any unlinearised node and repeatedly follow any edge while keeping track of what nodes you've visited until you reach a node you've visited before, then report the stack of nodes you've followed until you get back to that node. This will work even in a disjunctive graph. Note that none of these reports are errors - a bunch of these could be due to later Py mods disabling earlier items etc. Also note we can probably report a cycle for every connected component of the unlinearised part of the graph. Reporting more than one is probably not a good idea, because if you have one you tend to have many with duplicate nodes. Worst case, we can report a cycle, delete all the nodes involved, then continue Kahn's algorithm again, report another cycle, etc.

Step 3: the entire tech graph is logged. An inefficient way to construct the graph this is to perform a BFS from every tech, and then make an edge for every reachable tech. We can make two performance improvements:

The first optimisation is to make use of the observation that the BFS will not just find the dependent techs but all their transitive tech dependencies too, and that this is unnecessary. If we do a BFS on tech A, and we find tech B as dependency, which itself has tech C as dependency, then we don't need to add C as a dependency for A, because the BFS from B will already find C. We can achieve this by breaking up the tech and recipe nodes in the recipe graph. We make two nodes per tech: the 'unlock' node and the 'dependency' node. We do the same for recipes: we make an 'unlock' and 'dependency' node per recipe. The idea is that the BFS will start at the 'unlock' tech node, jump to the 'unlock' recipe nodes, traverse the rest of the graph, end up at the 'dependency' nodes for the required recipes, and then jump to the 'dependency' nodes for the techs. These 'dependency' nodes don't have any edges for the BFS to follow afterwards, so the BFS won't try to find the transitive tech dependencies.

The second optimisation is to make use of the linearisation to compute all the tech dependencies simultaneously instead of in many BFS passes. We can go in linear order through the nodes and propagate the techs that every node depends on by looking at all its edges and merging the tech dependencies of their targets. Note that this is not better in the worst case, if techs depend on a linear number of other techs, because then most of your time you're merging dependencies no matter whether you're using BFSses or not.

Step 4: just like step 2d, it's possible to report a cycle in the tech graph.

Step 5: the transitive reduction of the graph is the graph where you take away the largest number of edges without changing the transitive dependencies. For example, if tech A depends on C, but A also depends on B which depends on C already, then that dependency from A to C is pointless and can be removed. This is a slightly expensive step to compute but should make the tech tree more readable. We're already past all the steps that can give errors at this point though. There'll be a setting to turn this off it it takes too much time. All removed edges are logged.

Steps 6 and 7 are straightforward and discussed earlier respectively.

== Explanation without assuming a computer science background ==

=== Linear orderings ===

The autotech code makes heavy use of a concept called a 'linear ordering', so we're going to explain that first. Let's take the Factorio example of the automation science pack, which needs an iron wheel and copper plate to make. We can make a dependency graph between these items for the base game:

- iron ore -> iron plate
- copper ore -> copper plate
- iron plate -> iron wheel
- iron wheel -> automation science pack
- copper plate -> automation science pack

Thse five dependencies define what is called a 'partial ordering' on these nodes. It's an ordering because it tells you what nodes need to 'happen' before what other nodes, and it's partial because it leaves freedom as to the exact orderings that conform to the partial ordering. For example, these are some orderings that respect this partial ordering:

- iron ore, iron plate, iron wheel, copper ore, copper plate, automation science pack
- iron ore, copper ore, iron plate, copper plate, iron wheel, automation science pack
- copper ore, copper plate, iron ore, iron plate, iron wheel, automation science pack

These three examples each represent a specific ways to get to the automation science pack from scratch. They respect the partial ordering because for every dependency A -> B in the partial ordering, A comes before B in the examples. However, an ordering where for example the iron wheel comes first does not respect the partial ordering, and indeed it cannot correspond to a way to get to the automation science pack.

Actually, these three examples are in fact also examples of a 'linear order', because they fully pin down the ordering of events, as opposed to a partial order, which leaves some freedom. It's called 'linear' because if you consider it a graph, it's just a line. There's actually many names for it, such as 'complete ordering' or 'total ordering'. Every partial order can be respected by a lot of different linear orders.

Now, if you think about that dependency graph from earlier as a graph, you may notice it's a directed acyclic graph. This is true in general: every directed acyclic graph corresponds to a partial ordering, they're basically the same thing but in a different context. Cycles are obviously bad for orderings, because no 'solutions' exist - if A depends on B depends on C depends on A, then no ordering of A, B and C can respect those dependencies, hence the need to have an acyclic graph.

'Linearisation' is the process of turning a partial order into a linear order. Intuitively, this means we pick a possible 'path' of the nodes in the dependency graph that respects the partial ordering. Usually, linearisation algorithm do a bit more than just compute a linearisation: they also detect cycles. They start with a directed graph, detect cycles and if no cycle exist they output a linearisation. Note there can be multiple or even many possible linearisations of a partial order (as seen in our example): linearisation arbitrarily picks one of them.

=== Disjunctive graphs ===

The second concept important to autotech is a 'disjunctive graph'. It solves the problem that in Factorio, you often have a choice to make something, so a strict dependency graph like we presented earlier doesn't work. For example: in vanilla Factorio, water can come from an offshore pump but also from emptying a water barrel. Petroleum can come from basic oil processing, advanced oil processing, light oil cracking and emptying a petroleum barrel. This is even more egregious in Pyanodon, because items can have many recipes and there will be playthroughs A and B that obtain an item exclusively through differing recipes. The strict dependencies as described in the previous section are therefore not good enough - you cannot say that making Vrauks necessarily comes from the simpler or the more complex recipe to make it.

Enter the disjunctive graph. Instead of having edges of the form A -> B, so "You need B to make A", you can have edges of the form A -> {B, C}, so "You need B _or_ C to make A". Conceptually, this is pretty simple, but it makes autotech significantly harder. The good news is that linearisation, cycle detection and reachability (eg 'can I get from the starting point to the final technology') are all easy with disjunctive graphs, as the normal algorithms keep working with minimal changes. The bad news is that the ultimate thing we'd like to know, namely 'what techs do I need in order to be able to use a recipe', becomes an algorithm with an exponential runtime if we want to compute it fully correctly. Luckily, we can take a shortcut that will work in all practical cases.

=== Recipe graph and tech graph ===

Let's first describe the exponential algorithm, since it helps understanding the final algorithm. We will skip the explanation why the last step is exponential. We first make the 'recipe graph': we make a node for every Factorio 'thing', so items, recipes, crafting categories, entities, fuel categories, etc. We then add edges and disjunctive edges representing how Factorio works. For example, every item has a disjunctive edge to the recipes that make it, the ore entities that it can be mined from or the fuels it is the burnt result from, etc. Every recipe has a normal edge to the crafting category for that recipe, which in turn has a disjunctive edge to all the entities that can craft that crafting category, etc. This makes the recipe graph a disjunctive graph that describes the partial order of all possible playthroughs of Factorio (given a modset). Every actual playthrough is a linear ordering of the Factorio 'things' that adheres to the recipe graph.

Yes, the name 'recipe graph' is not correct as it contains more than just recipes, but calling it a 'Factorio thing graph' doesn't sound as good.

Making the recipe graph is fast and super useful, so we will also do it in the actual final algorithm. It allows us to figure out a bunch of things: what items and recipes are impossible to get in a playthrough, either because they are fundamentally unreachable or because they're part of a dependency loop? Can we research the victory tech at all? Note that not all unreachable items are bad: they may just be disabled items that are not actually needed, for example 'organic material' in Py before PyAL, which gets disabled and replaced with 'biomatter' when PyAL is turned on. The new autotech reports these unreachable things in the log, but doesn't error out on them, which should help debug issues.

The ultimate thing that autotech aims to figure out is what techs you need in order to be able to run all the recipes unlocked by a tech. We therefore want to make a second graph, the 'technology graph', where the nodes are techs, and the edges are these dependencies. To spell that out a bit more: let's say technology A unlocks recipe X. The aim is that when you unlock A, no matter what techs you've chosen before, you should be able to use the recipes you have at that point to be able to run recipe X in your factory. You need to be able to make every ingredient of X, you need to be able to have a building that can run X, etc.

This is a question that the recipe graph can answer. However, both reachability and cycle detection are not good enough for our goals. Reachability especially just tells you that there is _some_ way to go from a tech to a recipe, but it's allowed to assume you research other techs, so it's not good enough. Similarly, linearisation will just tell you _some_ set of techs that will allow you to use that recipe, but not the minimal number of techs. There is an algorithm that computes this 'technology graph' correctly, however, I will not describe it here due to the problems described in the next paragraph.

There are two problems with this approach (not just the algorithm): the first is that this technology graph is likely to be exponentially large (no matter the algorithm used to compute it), and the second is that it's still a disjunctive graph, so it allows for choices between tech dependencies, and it's unclear what to do with this information. Factorio does not allow disjunctive dependencies between techs - you can't say that technology A can be unlocked by researching either technology B or C - so we can't just apply the technology graph to Factorio. We'd have to turn it into a non-disjunctive dependency graph first somehow.

=== The solution ===

The solution to the above problem is to de-disjunctify the recipe graph. The plan is to pick for every disjunctive edge a 'canonical' choice, and transform the edge into a normal one. For example, for petroleum in the base game, we can get it via several recipes like cracking, but we will choose basic oil processing as the 'canonical' choice, because it's the first recipe you can get that can make petroleum. Furthermore, all the other recipes that make petroleum need petroleum themselves to research (for advanced oil processing) or to make one of the ingredients (barrel of petroleum), so they are not valid canonical choices. The resulting non-disjunctive recipe graph no longer allows all possible playthroughs of the modpack, but it still has useful information about the dependencies between Factorio things. Examples where information is 'lost' are basically those where multiple options exist to get something, for example multiple recipes to make PyAL animals, or things like acid gas which you can obtain in several ways. In practice I don't think this matters though.

After picking a canonical choice for all edges in the recipe graph, it has become a normal directed graph, and we can compute the tech graph from it much faster than in exponential time. This tech graph is now a normal graph as well, which means we can use it as a basis for computing tech dependencies as intended.

We do have to pick canonical chocies in such a way that the graph stays useful as mentioned earlier. The way we will do this is by computing a linear order first, and then resolving all disjunctive edges according to the first element in the computed linear order. In other words, for the case of choosing which recipe to use for your first Vrauk, we look at what the linear order did, and then choose that recipe. The advantage of this is that that linear order will still be a valid linear order on the resulting graph, so if the victory tech was reachable before, it would still be reachable after this de-disjunctivication.

So, in summary:
- compute the disjunctive recipe graph
- compute a linear order on this graph
- canonise the disjunctive recipe graph into a normal recipe graph according to the linear order
- compute the tech graph out of this normal recipe graph
- correct Factorio tech graph to match this tech graph, adapt tech costs

That's the gist of the algorithm. There's some more smaller details we'll go over now.

Two details about the recipe graph: we'll need a file that adds 'scripted dependencies' like guano to the recipe graph, and we'll need to respect the flag we have for e.g. soot sorting that should not lead to seeing soot as a source of silver.

=== Logging versus reporting versus error ===

The new autotech will have 3 reporting levels. Error means something is broken and we cannot continue, which only happens in two scenarioes I believe:
- the victory tech is unreachable
- there is a dependency loop between technologies

The second level is 'reporting', which is when it finds something suspicious but not broken, for example unreachable items or dependency loops outside the tech graph. These will be printed but will not stop the autotech process.

The third level is 'logging', which is where it will print out every decision it makes. It will print out the full recipe graph, linear order, canonicalisation choices, etc. This should help in investigating dependency loops.

I have an algorithm to report a dependency loop when one is found, which should make debugging a lot easier.

=== Transitive reduction ===

A lot of people know the term 'transitive closure', but that concept has a brother called 'transitive reduction'. The transitive reduction of a graph A is the graph where the most edges are removed without changing the reachability in the graph. For example, if A depends on B, B depends on C and A depends on C, then you can remove the 'A depends on C', because A can already reach C via B. This basically removes 'clutter' edges in the tech graph that don't actually do anything.

I plan to have this be applied to the tech graph computed by autotech. This means it may actually end up _removing_ superfluous dependencies between techs, which is something the current autotech does not do.

=== Unit tests ===

I want to make code to dump the data.raw table into a JSON file, so we can then run autotech on just this JSON file. This has several advantages:
- easier development, because you don't have to start the game every time you want to run the code
- automated regression testing becomes easier - you can just run some Python tests if you're modifying autotech after it already works
