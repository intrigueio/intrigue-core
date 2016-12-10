[ ![Codeship Status for Linkurious/linkurious.js](https://www.codeship.io/projects/b0710040-7f11-0132-f563-62fa786c5210/status)](https://www.codeship.io/projects/57170)
[![Issue Stats](http://issuestats.com/github/Linkurious/linkurious.js/badge/pr?style=flat)](http://issuestats.com/github/Linkurious/linkurious.js)
[![Issue Stats](http://issuestats.com/github/Linkurious/linkurious.js/badge/issue?style=flat)](http://issuestats.com/github/Linkurious/linkurious.js)
[![Join the chat at https://gitter.im/Linkurious/linkurious.js](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/Linkurious/linkurious.js?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Give Feedback Badge](http://gitrank.io/assets/images/giveFeedbackBadge.svg)](http://gitrank.io/github/Linkurious/linkurious.js/feedback)

linkurious.js
=================
**A JavaScript library to visualize and interact with graphs.**

Linkurious.js is an active fork of [Sigma.js](https://github.com/jacomyal/sigma.js). It's dual-licensed under both GPLv3 and a [commercial license for proprietary projects](https://linkurio.us/toolkit/#pricing).


* [Live demo on JSFiddle](https://jsfiddle.net/6voan7k9/)
* [Examples](https://rawgit.com/Linkurious/linkurious.js/develop/examples/)
* [Plugins](https://rawgit.com/Linkurious/linkurious.js/develop/plugins/list.html)
* [Download](https://github.com/Linkurious/linkurious.js/releases/latest)
* [Documentation](https://github.com/Linkurious/linkurious.js/wiki)
	 - [Vizualisation API](https://github.com/Linkurious/linkurious.js/wiki/Public-API)
	 - [Graph API](https://github.com/Linkurious/linkurious.js/wiki/Graph-API)
	 - [Settings available](https://github.com/Linkurious/linkurious.js/wiki/Settings)

The library is used by [Linkurious SAS](http://linkurio.us) as the main building block for the [Linkurious](http://linkurio.us/product/) product.

---

[
![glyphs-icons](https://github.com/Linkurious/linkurious.js/wiki/media/glyphs-icons-230.gif)
![edge-shapes](https://github.com/Linkurious/linkurious.js/wiki/media/edge-shapes-230.gif)
![filters](https://github.com/Linkurious/linkurious.js/wiki/media/filters-230.gif)
![forceatlas](https://github.com/Linkurious/linkurious.js/wiki/media/forceatlas-230.gif)
![glyphs](https://github.com/Linkurious/linkurious.js/wiki/media/glyphs-230.gif)
![halo](https://github.com/Linkurious/linkurious.js/wiki/media/halo-230.gif)
![hover-edge](https://github.com/Linkurious/linkurious.js/wiki/media/hover-edge-230.gif)
![designer](https://github.com/Linkurious/linkurious.js/wiki/media/designer-230.gif)
![drag](https://github.com/Linkurious/linkurious.js/wiki/media/drag-multiple-nodes-230.gif)
![layout-arctic](https://github.com/Linkurious/linkurious.js/wiki/media/layout-arctic-230.gif)
![level-of-details-edges-labels](https://github.com/Linkurious/linkurious.js/wiki/media/level-of-details-edges-labels-230.gif)
![node-icons](https://github.com/Linkurious/linkurious.js/wiki/media/node-icons-230.gif)
![pie-charts](https://github.com/Linkurious/linkurious.js/wiki/media/pie-charts-230.gif)
![self-loop](https://github.com/Linkurious/linkurious.js/wiki/media/self-loop-230.gif)
![tooltips](https://github.com/Linkurious/linkurious.js/wiki/media/tooltips-230.gif)
](https://github.com/Linkurious/linkurious.js/wiki)

---

### Getting started

For prototyping, you can directly use `rawgit`:

```html
<script src="https://rawgit.com/Linkurious/linkurious.js/develop/dist/sigma.min.js"></script>
```

And look at the [examples](https://github.com/Linkurious/linkurious.js/tree/develop/examples).

### Getting help

The easiest way is to [file an issue](https://github.com/Linkurious/linkurious.js/issues/). You can also ask on [StackOverflow](http://stackoverflow.com/search?q=linkurious.js) if you want more general help with JavaScript and [gitter](https://gitter.im/Linkurious/linkurious.js) if you want to chat with us.

### Building the library

```
git clone git@github.com:Linkurious/linkurious.js.git
```

You can try the examples in the `examples/` directory to see how to use sigma.

To build the code:

 - `git clone git@github.com:Linkurious/linkurious.js.git`
 - Install [Node.js](http://nodejs.org/).
 - Install [gjslint](https://developers.google.com/closure/utilities/docs/linter_howto?hl=en).
 - Use `npm install` to install dev dependencies.
 - Use `npm run build` make the minified files (`sigma.min.js`, plugins) under the `build/` folder.

You can customize the build by adding or removing files from the `coreJsFiles` array in `Gruntfile.js` before applying the grunt task.

You can get the latest release directly from the `dist/` without having to build it yourself.


### Why linkurious.js?

At [Linkurious SAS](http://linkurio.us) we are big fans of Sigma.js. We use it extensively in our applications because it is an efficient graph *viewer*, but application developers like us need more high level and integration-ready features to create smart graph applications. We have thus developed more than 20 plugins and improved the core of Sigma with enhanced interaction features.

We define our mission as follows:

1. To work on **core fixes** and core improvements in collaboration with the Sigma.js team.
2. To develop **integration-ready features** such as filters, tooltips, or Excel exporter.
3. To provide **professional support** for developers to succeed in their projects.

### Benefits

You should consider linkurious.js as your primary toolkit for building graph-based applications on the Web if you need:
* to ship your solution quickly;
* to focus on the core value of your application;
* to display large graphs (i.e. larger than 2000 nodes and 5000 edges);
* to interact with the graph visualization;
* development support.

### Browser Support

All modern web browsers are supported, including:
* Internet Explorer 10+
* Chrome 23+ and Chromium
* Firefox 15+
* Safari 6+

Touch events on tablet and mobile are currently supported as *beta* features.

### Performance

See our [performance guide](https://github.com/Linkurious/linkurious.js/wiki/Performance) to learn more.

### External Dependencies

Linkurious.js comes with no external dependency, making it compatible with any Javascript framework and library. We integrate it with [Angular.js](https://angularjs.org/) in a Linkurious product.

A few plugins may require external dependencies. Please check their README files.

### Contributing

You can contribute by submitting [issues tickets](http://github.com/Linkurious/linkurious.js/issues) and proposing [pull requests](http://github.com/Linkurious/linkurious.js/pulls). Make sure that tests and linting pass before submitting any pull request by running the command `grunt`.

See [How to fix bugs](https://github.com/Linkurious/linkurious.js/wiki/How-to-fix-bugs) and to [How to develop plugins](https://github.com/Linkurious/linkurious.js/wiki/How-to-develop-plugins).

The whole source code is validated by the [Google Closure Linter](https://developers.google.com/closure/utilities/) and [JSHint](http://www.jshint.com/), and the comments are written in [JSDoc](http://en.wikipedia.org/wiki/JSDoc) (tags description is available [here](https://developers.google.com/closure/compiler/docs/js-for-compiler)).


### License

The linkurious.js toolkit is dual-licensed, **available under both commercial and open-source licenses**. The open-source license is the GNU General Public License v.3 ("GPL"). In addition to GPL, the Linkurious.js toolkit is available under commercial license terms from [Linkurious SAS](http://linkurio.us).

GPL has been chosen as the open-source license for linkurious.js, because it provides the following four degrees of freedom:

1. The freedom to run the program for any purpose.
2. The freedom to study how the program works and adapt it to specific needs.
3. The freedom to redistribute copies so you can help your neighbor.
4. The freedom to improve the program and release your improvements to the public, so that the whole community benefits.

These four degrees of freedom are very important for the success of linkurious.js, and it is important that all users of linkurious.js under GPL adhere to these and fully meet all the requirements set by the GPL. It is recommended that a thorough legal analysis is conducted when choosing to use the GPL or other open-source licenses. **If your application restricts any of these freedoms, such as commercial or closed-source applications, then the GPL license is not suited and you must contact us to buy a commercial license at contact@linkurio.us.**
