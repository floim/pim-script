PimScript
=========

Converts untrusted third party JavaScript so that it is safe to run on
your web page/web app.

Currently transforms code to be [ADsafe][] compliant - ADsafe is the
last step in the chain so you only need to trust that. (You can pass the
outputted code through ADsafe manually if you like - it will pass if
you're using the same version of JSLint as we are.)

Why?
----

We wanted a way of adding a layer of security to 3rd party plugins in
[Pim][], to help defend users against rogue plugins.

How it works
------------

** SUBJECT TO CHANGE **

PimScript takes your normal JavaScript code and mangles it to produce
something hopefully compliant with Douglas Crockford's [ADsafe][], which
is based on his [JSLint][]. Note, however, that your code shouldn't be
ADsafe compliant to start with - think of it like FBJS - it does all
that for you.

We're currently using [UglifyJS][] for mangling - we've had to make a
couple of minor tweaks to UglifyJS which you can find in [Benjie's
fork][UglifyJS-Benjie].

There is no guarantee that PimScript will always be based on ADsafe.

Structure of a PimScript
------------------------

### Header

The PimScript header contains details about the plugin/app/widget that
affect how it runs, so it is highly important. Here's an example:

    /*!PIM_APP{
      "name":"My Script"
    , "version":"0.0.1"
    , "access": ["app", "formatter"]
    }*/

**Name**: a short name for your app/plugin/widget.  
**Version**: the version, uses [semver][].  
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
- PimScript rewrites this for you - you shouldn't call `ADSAFE.get`
  directly).

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
pipe it through PimScript to do all that for you - this is especially
good if you already use CoffeeScript to write your ADSAFE JavaScript.


Host environment
----------------

We're not sure if getting a working install of PimScript will be
interesting for other people - if it is, let me know (b at p.im) and
I'll update this README with details on what to do, and add some example
code.


[Pim]: https://p.im/
[ADsafe]: http://www.adsafe.org/
[JSLint]: http://www.jslint.com/
[semver]: http://semver.org/
[UglifyJS]: https://github.com/mishoo/UglifyJS
[UglifyJS-Benjie]: https://github.com/benjie/UglifyJS
