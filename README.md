PimScript
=========

Runs untrusted third party JavaScript in a "jail" to allow it to
enhance your web-page/web-app without causing huge security issues.

Currently transforms code to be [ADsafe][] compliant.

Why?
----

We wanted a way of adding a layer of security to 3rd party plugins in
[Pim][], to help defend users against rogue plugins.

How it works
------------

PimScript currently uses Douglas Crockford's [ADsafe][], which is based
on his [JSLint][]. However, PimScript is intended to be thought of as
more alike to FBJS - JS that is rewritten to run jailed without
causing the original developer too much hassle.

PimScript takes your JavaScript and then rewrites it (via AST
manipulation using [UglifyJS][]) to be ADsafe compatible. If the code
cannot be made ADsafe then the JSLint errors are output to allow the
developer to tweak his code to be more compliant.

There is no guarantee that PimScript will always be based on ADsafe.

Structure of a PimScript
------------------------

### Header

The PimScript header contains details about the plugin/app/widget that
affect how it runs, so it is highly important. Here's an example:

    /*!PIM_SCRIPT{
      "name":"My Script"
    , "version":"0.0.1"
    , "access": ["plugin", "formatter"]
    }*/

**Name**: a short name for your plugin/widget.  
**Version**: the version of this script, uses [semver][].  
**Access**: an array of the items that access is requested to.

### Access

The runtime environment will give the script access to each of the
requested objects (these will need to be exported in ADsafe ways so that
the plugin cannot break out of its jail), they will be made available in
the global scope of the script (i.e. the script above can directly
access the `plugin` and `formatter` objects.)

### Body

The body of the PimScript is simply JavaScript, however many of the
variables you'd expect have been removed from the scope - there's no
access to `window`, `document`, `alert`, `eval`, etc. Compile-time checks ensure
that you don't try to access these variables (if you do then `pimscript`
will fail to compile your script, and will tell you why). Run-time
checks also help to protect too - for example all object properties are
accessed via `ADSAFE.get` (though this is invisible to the plugin writer
- PimScript rewrites this for you).

Things to avoid
---------------

JSLint/ADsafe are quite strict with their JavaScript parsing. PimScript
tries to rewrite bits of your code to increase the chances of passing
before feeding it to ADsafe. If your code is already high enough quality
to pass JSLint in `safe` mode without errors then you'll certainly have
a better chance of your script working!

### Continue
For some reason JSLint doesn't like `continue` statements. Simply avoid
them.

### Object-oriented programming

ADsafe blocks access to `prototype`, `constructor` and the like for
security reasons, so OO programming will be quite challenging. It's
suggested that you try more expressive functional-style programming.

Other uses
----------

I suppose you could quite easily hack PimScript to be a pre-compiler for
ADsafe code - no longer would you need to worry about writing all your
own `ADSAFE.get` calls, etc., just write your code normally and then
pipe it through PimScript to do all that for you.


[Pim]: https://p.im/
[ADsafe]: http://www.adsafe.org/
[JSLint]: http://www.jslint.com/
[semver]: 
[UglifyJS]: 
