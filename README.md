bare_unity
==========

This is a stripped down version of the [Unity](https://github.com/ThrowTheSwitch/Unity) C testing framework.

The C code is untouched. What has changed is the way the test runners are generated.

To that purpose the original scripts are all gone and in their place there is a single generator that uses an ERB template to create the test runner.

In the original Unity test runner generator the runner's C code is embedded in the Ruby script. This makes it difficult to adapt the runner with C code to i.e. run in a specific embedded device.

Most often I have had to do this in order to add support for code coverage measurements on embedded devices.

Compared to the original Unity the following are not supported:

 * Plugins
 * Ordered tests 
 * Parametrized tests
 * CMock

I will not add ordered test execution as I considder it very dagerous and against the principle of testing in isolation.

CMock is on the todo list and will be added very soon (Unity without CMock is like running a marathon with your shoelaces tied). Parametrized tests will be added on a need basis and plugins will probably be left out as Unity & CMock cover all needs to date.
