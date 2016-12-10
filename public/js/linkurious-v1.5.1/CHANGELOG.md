## linkurious.js - changelog:

#### 1.5.1 (March 30, 2016)

**Plugins:**
- #351 layouts.forceLink Layout pulls nodes too close together
- #285 Fix exporters.image: Incomplete image export on Retina screen

#### 1.5.0 (February 27, 2016)

This release improves rendering performance by x7 and reduces memory used indexes by x2. Indexes will use ES6 Map instead of Object if possible. It also provides a new plugin to integrate geospatial visualization with Leaflet. Rendering of node border has been changed (breaking) with new settings:

- Rename `borderSize` to `nodeBorderSize`
- Rename `outerBorderColor` to `nodeOuterBorderColor`
- Add `nodeBorderColor`, `nodeOuterBorderColor`, `nodeOuterBorderSize`, `defaultNodeOuterBorderColor`
- Add `nodeHoverBorderColor`, `nodeHoverOuterBorderColor`
- Add `nodeActiveBorderSize`, `nodeActiveBorderColor`, `nodeActiveOuterBorderColor`, `nodeActiveOuterBorderSize`, `defaultNodeActiveOuterBorderColor`

**Core:**
- #348 Defaut size to added nodes and edges
- #347 Convert x,y,size as number if they are string
- Fix #342 Regression: slow camera
- #333 Distinct border settings to nodes, hovered nodes, active nodes (**BREAKING CHANGES**)
- #330 Fire `coordinatesUpdated` event
- #329 Add `zoomOnLocation` setting
- Fix #328 Node coordinates change if autoRescale array doesn't contain 'nodesPosition'
- #284 Make local indexes more memory-efficient

**Plugins:**
- Fix #341 ForceAtlas2 adjustSizes setting is ignored (thanks @rangeonnicolas)
- #340 plugins.activeState: get nb active nodes and edges in O(1)
- #339 plugins.dragNodes: prevent drag if all nodes are active
- #338 plugins.design: add downloadable palette and styles as .toJSON()
- #337 plugins.design: add reference to items in histogram
- Fix #336 plugins.design: 'One value of the property x is not a number.' thrown if sequential property has no value
- #335 plugins.fullScreen should be able to display control UI elements
- Fix #334 layouts.dagre: exception if node ids are numbers
- #332 Support for multiple tooltips (thanks @mujx)
- Fix #326 plugins.dragNodes: wrong mouse canvas if it is not the last canvas element
- Fix #325 plugins.select: Two adjacent nodes can be selected after selecting an adjacent edge
- #150 Add Leaflet integration for geospatial
- Fix #120 exports.svg: images are cut-off in Inkscape and browser

#### 1.4.0 (December 17, 2015)

This release fixes multiple rendering issues. It provides better support to SVG renderers and export.

**Core:**
- #321 Add curved edges for SVG
- #321 SVG edge renderer handles defaultEdgeType setting
- #321 Exported SVG is rescaled automatically to the specified size
- Fix #319 sigma.renderers.svg.resize doesn't take arguments into account
- Fix #316 Two parallel edges with opposite directions overlap
- Fix #315 The last parallel edge after dropping the other edges remains curved
- #295 Multi-line node labels on Canvas
- Fix #266 'minArrowSize' settings not work (thanks @bkkoo)

**Plugins:**
- #322 Add a margin to exporters.svg
- #289 renderers.linkurious: Add tapered edges for SVG
- Fix #286 sigma.statistics.louvain Uncaught RangeError: NaN included (thanks @partizanos)
- #131 renderers.edgeLabels: Add edge labels for SVG

#### 1.3.0 (October 30, 2015)

This release has BREAKING CHANGES regarding plugins.image and sigma.layout.*. Is also brings a new plugin that will provide nice legends to visualizations.

**Plugins:**
 - #303 layouts.forcelink: pinned nodes coord are updated if previously laid out while unpinned
 - #240 Rename plugins.image -> exporters.image
 - #239 Rename sigma.layout.* -> sigma.layouts.*
 - #188 Add plugins.legend

#### 1.2.0 (October 15, 2015)

This release is greatly powered by the community. Multiple plugins are stabilized and important features are added for rendering and integration.

Hightlights:
- Support of [WebPack](http://webpack.github.io/) module builder
- New file exporters in GraphML and JSON
- Nodes can have borders (aka strokes) without hover
- Curve parallel edges automatically (i.e. edges with same extremities), add new settings: `autoCurveRatio`, `autoCurveSortByDirection`
- The dragNodes plugin becomes stable

Core:
 - Fix #247 No hovering or graph disappears when nodes are on the same axis (thanks @mdamien)
 - #242 Factorize quadtree & edgequadtree (thanks @mdamien)
 - Fix #241 Only one label displayed on all examples (thanks @mdamien)

Plugins:
 - Fix #287 minimum edges louvain (thanks @partizanos)
 - #282 Add "constrained" labelAllignment setting (thanks @NicholasAntonov )
 - Fix #281 Prevent dragNodes during animations
 - Fix #278 getTextWidth not being called correctly (thanks @NicholasAntonov)
 - Fix #277 bugs when sigma was required with webpack (thanks @NicholasAntonov)
 - #273 Add parametric edge curvature (canvas renderer) (thanks @ekkis)
 - #270 renderers.linkurious: add node border on canvas (without hover) (thanks @ekkis)
 - #267 A* plugin, v1.0.1 Fix non-optimal path (thanks @A----)
 - #263 parsers.cypher: increase robustness (thanks @ekkis)
 - #253 plugins.tooltips: fire 'shown' after the open() function was fully executed (thanks @mdamien)
 - Fix #248 Animate set node coordinated to undefined if the target position are not included (thanks @mdamien)
 - #245 plugins.dragNodes: add sticky effect (avoid drag on clicking inside the node)
 - #237 Add exporters.graphml (thanks @Ytawo)
 - #186 Add exporters.json

Docs:
 - #53 Add documentation on sigma lifecycle


#### 1.1.0 (August 10, 2015)

This release provides A BREAKING CHANGE from the core of Sigma.js and focuses on performance.

Hightlights:
 - linkurious.js is now available on npm: `npm install linkurious`
 - Latest release files directly in `dist/` and a plugins.(.min).js containing all the plugins
 - Crisp render on retina displays
 - Added plugin.generators to generate graphs
 - Panning, zooming and hovering is a lot smoother on Canvas
 - New setting: `edgesClippingWithNodes` to hide the edges having both extremities outside of the view if `true`
 - Contributors, we have a new workflow: #201 (in short: all plugins are merged into the *develop* branch)

How to upgrade:
  - replace `overNode(s)`, `outNode(s)`, `overEdge(s)`, `outEdge(s)` events by the `hovers` event

Core:
  - #235 Add plugins.js and plugins.min.js and clean grunt/package.json things (thanks to [@mdamien](https://github.com/mdamien))
  - #229 Alert the user if webgl is not supported but trying to render with the WebGL renderer (thanks to [@mdamien](https://github.com/mdamien))
  - #224 Fix Edges not rendered when extremities are far from the view (thanks to [@mdamien](https://github.com/mdamien))
  - #223 Remove width hack and clear canvas via clearRect (thanks to [@mdamien](https://github.com/mdamien))
  - #222 Improve pan/zoom smoothiness on canvas (thanks to [@mdamien](https://github.com/mdamien))
  - #221 Aggressively simplify hovering system (replace `overNode(s)`, `outNode(s)`, `overEdge(s)`, `outEdge(s)` by `hovers`) (thanks to [@mdamien](https://github.com/mdamien))
  - #213 Fix `onMove` render twice during a panning event (thanks to [@mdamien](https://github.com/mdamien))
  - #210 Publish on npm (thanks to [@mdamien](https://github.com/mdamien))
  - #208 Add dist/ folder with latest release (thanks to [@mdamien](https://github.com/mdamien))
  - #204 Improve node labels renderers (thanks to [@mdamien](https://github.com/mdamien))
  - #203 New rendering system and faster edge labels renderer (thanks to [@mdamien](https://github.com/mdamien))
  - #25 Fix retina display (thanks to [@mdamien](https://github.com/mdamien))

Plugins:
  - #233 Fix plugins.select throws "Uncaught TypeError" on Spacebar+Del 
  - #226 Fix layout.dagre only runs the first time that is called
  - #209 Fix plugins.tooltip: wrong position on sigma container with margins
  - #198 plugins.tooltip: Add option to delay hide execution on outNode and outEdge
  - #196 renderers.halo: Merge circles via two-pass rendering (thanks to [@mdamien](https://github.com/mdamien))
  - #194 Include renderers.customEdgeShapes into renderers.linkurious (thanks to [@mdamien](https://github.com/mdamien))
  - #181 Fix plugins.image crashes on batchEdgesDrawing: true
  - #177 Fix layout.fruchtermanReingold only runs the first time it is called
  - #168 renderers.linkurious: Cache `context.font` value when rendering  (~20% rendering overall speedup) (thanks to [@mdamien](https://github.com/mdamien))
  - #104 Add plugins.generators

Docs:
  - #201 [NEWS] Changes on the dev workflow
  - #238 Add AUTHORS file

#### 1.0.10 (July 18, 2015)

Core:

  - #167 Optimize label alignment of latin fonts via a faster context.measureText() by adding `approximateLabelWidth` to Sigma settings (`false` by default) (~12% rendering overall speedup) (thanks @mdamien)
  - #167 src/renderers/canvas/sigma.canvas.labels.def.js: Add backward-compatible support of `approximateLabelWidth` setting (thanks @mdamien)
  - #158 src/renderers/sigma.renderers.webgl.js: Fix lines in reverse order
  - #152 Add backward-compatible `beforeRender` event (see also https://github.com/jacomyal/sigma.js/pull/606) (thanks @mdamien)
  - #143 Add backward-compatible `nodeQuadtreeMaxLevel` and `edgeQuadtreeMaxLevel` to Sigma settings (`4` by default) (see also https://github.com/jacomyal/sigma.js/pull/602)
  - #96 use `throw new Error('msg')` instead of `throw 'msg'` to get stack trace (see also https://github.com/jacomyal/sigma.js/pull/536)

Plugins:

  - #185 exporters.gexf: File exports fail in IE10+
  - #185 exporters.spreadsheet: File exports fail in IE10+
  - #145 exporters.spreadsheet: Add column for node and edge categories/types
  - #187 exporters.svg: Fix SVG export fails in IE10+ (see also https://github.com/jacomyal/sigma.js/pull/621)
  - #185 exporters.xlsx: File exports fail in IE10+
  - #136 exporters.xlsx: Add column for node and edge categories/types 
  - #128 helpers.graph: Add option in adjacentNodes() to get non-hidden nodes only
  - #128 helpers.graph: Add option in adjacentEdges() to get non-hidden edges only
  - #126 Add layout.forceLink and restore original layout.forceAtlas
  - #192 Add layouts.dagre for Direct Acyclic Graph (DAG) / hierarchical layout.
  - #139 parsers.cypher: Fix edgeColor setting don't work
  - #142 plugins.activeState: Fix event not fired on invert functions if no node/edge is active afterwards
  - #138 plugins.design: Fix cannot format string labels using the nodes.labels.by function
  - #122 plugins.design: Fix Error: Missing key "7" in nodes palette " of color scheme nodes.qualitative.categories"
  - #137 plugins.dragNodes: Add stickiness setting
  - #163 plugin.filter: Fix test not passing on firefox (thanks @mdamien)
  - #185 plugins.image: File exports fail in IE10+
  - #134 plugins.keyboard: Fix page jump on Chrome, Safari and IE when mouseover graph that isn't fully in view
  - #121 plugins.keyboard: Fix zoom in/out ignores zoomMin/zoomMax settings
  - #146 plugins.select: Fix do not select edges on mouse move (expected: panning)
  - #174 renderers.customEdgeShapes: Fix hover erroring if edgeLabels plugin not here (thanks @mdamien)
  - #167 renderers.edgeLabels: Add support of `approximateLabelWidth` setting
  - #166 renderers.edgeLabels: Computations only if useful (thanks @mdamien)
  - #125 renderers.edgeLabels: Add edge label hovering effects
  - #124 renderers.edgeLabels: set angle=0 when edge length > text width
  - #153 renderers.glyphs: Fix `drawGlyphs` setting not working
  - #154 renderers.halo: Add `drawHalo` setting
  - #133 renderers.halo: Add clustering of node halo
  - #132 renderers.halo: Add stroke to node halo
  - #129 renderers.halo: Fix halo is displayed on hidden nodes and edges
  - #167 renderers.linkurious: Add support of `approximateLabelWidth` setting
  - #125 renderers.linkurious: Add edge label hovering effects

Tests:

  - #159 Add smoke tests for renderers (see also https://github.com/jacomyal/sigma.js/pull/610) (thanks @mdamien)

#### 1.0.9 (May 20, 2015)

Plugins:

  - Fix #109 sigma.plugins.locate: handle multiple sigma instances
  - #108 sigma.plugins.locate: add an optional padding
  - Fix #107 sigma.plugins.select: A node is deactivated on double-click
  - Fix #106 sigma.plugins.dragNodes: Dragging an unselected node while another node is selected drags both
  - Fix #105 sigma.plugins.select: A node is deactivated on drag

#### 1.0.8 (May 18, 2015)

Plugins:

  - #94 Add sigma.layouts.fruchtermanReingold
  - Add sigma.parsers.cypher (license GNU GPL3 from @sim51)
  - Add levels to Linkurious renderers (canvas)
  - use throw new Error('msg') instead of throw 'msg'
  - plugins.lasso: Ensure that lasso does not select hidden nodes (thanks @apitts)
  - exporters.gexf: Change initial type to integer in GEXF exporter (thanks @apitts)
  - plugins.design: Minor fix in histogram on a missing "color" key

#### 1.0.7 (March 29, 2015)

Core:

  - Switch `clone` setting to `false` by default
  - Switch `singleHover` setting to `true` by default

Plugins:

  - plugins.design: Add method to deal with deleted node/edge properties
  - plugins.design: Preserve `color` key when `colors` exist for backward-compatibility
  - plugins.activeState: improved event trigger system
  - #64 renderers.linkurious: should use defaultNodeHoverColor
  - #86 renderers.glyphs: glyphs displayed on hidden nodes
  - #88 plugins.dragNodes: do not drag on right click
  - #84 plugins.dragNodes: node still selected after a click on its neighbor

Examples:

  - Add select-and-drag-nodes.html

Dev:

  - Update devDependencies

#### 1.0.6 - draft (March 05, 2015)

  - Update Sigma to [jacomyal/sigma.js#287f49616a5674ddcf30775d37f9c564cacf8e2a](https://github.com/jacomyal/sigma.js/commit/287f49616a5674ddcf30775d37f9c564cacf8e2a)

  - New plugin `sigma.pathfinding.astar` to find shortest paths (thanks to [@A----](https://github.com/A----))
  - New plugin `sigma.statistics.louvain` for community detection (thanks to [@upphiminn](https://github.com/upphiminn))
  - Revamp plugin `sigma.plugins.dragNodes` to support multiple nodes (thanks to [@martindelataille](https://github.com/martindelataille))

Improvements:

  - #69 sigma.layout.forceAtlas2: make maxIterations and avgDistanceThreshold configurable
  - #66 sigma.plugins.design: add support of type, icon, and image
  - #62 sigma.plugins.design: add color generation for qualitative data
  - add label alignment settings for canvas (thanks to [@qinfchen](https://github.com/qinfchen))

Bug fixes:

  - #78 sigma.plugins.image: sized images with zoom false are blurred
  - #74 sigma.plugins.locate.nodes() zooms out instead of zooming in
  - #72 sigma.plugins.design Histograms are not generated when there is only one value for a sequential property (thanks to [@callicles](https://github.com/callicles))
  - #60-#61 sigma.plugins.designer documentation
  - #59 sigma.plugins.designer doesn't support multiple sigma instances
  - #57 sigma.plugins.locate doesn't support multiple sigma instances
  - #56 sigma.plugins.tooltips doesn't support multiple sigma instances

#### 1.0.5 - draft (January 16, 2015)

  - New plugin `sigma.exporters.xlsx`
  - New plugin `sigma.plugins.lasso` (thanks to [@Flo-Schield-Bobby](https://github.com/Flo-Schield-Bobby))
  - New plugin `sigma.renderers.glyphs` (thanks to [@Flo-Schield-Bobby](https://github.com/Flo-Schield-Bobby))
  - Revamp plugin `sigma.renderers.customShapes` (thanks to [@jbilcke](https://github.com/jbilcke))
  - New plugin `sigma.renderers.linkurious` (thanks to [@jbilcke](https://github.com/jbilcke))
  - Add an option to animate a given set of nodes in `sigma.plugins.animate`

#### 1.0.4 - draft (November 27, 2014)

  - New plugin `sigma.exporters.gexf`
  - New plugin `sigma.exporters.spreadsheet`
  - New plugin `sigma.exporters.svg` (thanks to [@Yomguithereal](https://github.com/Yomguithereal))
  - New plugin `sigma.plugins.image`, fork of `sigma.renderers.snapshot` (thanks to [@martindelataille](https://github.com/martindelataille))
  - New plugin `sigma.plugins.keyboard`
  - New plugin `sigma.plugins.poweredBy`


#### 1.0.3 - draft (October 17, 2014)

  - Merge sigma.js 1.0.3
  - New plugin `sigma.plugins.colorbrewer`
  - New plugin `sigma.plugins.designer`
  - New plugin `sigma.plugins.fullScreen` (thanks to [@martindelataille](https://github.com/martindelataille))
  - New plugin `sigma.renderers.halo`
  - Add background execution and easing transition to `sigma.layout.forceAtlas2`
  - Improve `sigma.plugins.dragNodes`

#### 1.0.2 - draft (August 22, 2014)

  - Merge sigma.js 1.0.2
  - Add method `graph.attachBefore` to the core
  - Add spatial indexing of edges using a quad tree to the core
  - Add events on edges to the core
  - Add edge hovering to the core
  - New plugin `sigma.helpers.graph`
  - New plugin `sigma.plugin.activeState`
  - New plugin `sigma.plugin.edgeSiblings`
  - New plugin `sigma.plugin.filter`
  - New plugin `sigma.plugin.locate`
  - New plugin `sigma.plugin.select`
  - New plugin `sigma.plugin.tooltips`
  - New plugin `sigma.renderers.customEdgeShapes`
  - New plugin `sigma.renderers.edgeLabels`
  - Add auto-stop condition to `sigma.layout.forceAtlas2`
