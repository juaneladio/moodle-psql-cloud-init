# cloud-init-scripts
For automatically setting up a moodle virtual machine running ubuntu using multipass and cloud-init.

[Documentation](https://www.ntnu.no/wiki/display/iemoodle/%5BLOCAL+VM%5D+Automatic+moodle+setup+with+Multipass+and+cloud-init)

## Status on plugin compatibility
|       | cloud-init | cloud-init-dns-challenge | cloud-init-http-challenge |
|------:|:----------:|:------------------------:|:-------------------------:|
| Stack |      ✅     |             ❌            |             ❌             |
| CapQuiz |      ❔     |             ❌            |             ❌             |
| ShortMath |      ❔     |             ❌            |             ❌             |
| QTracker |      ❔     |             ❌            |             ❌             |
## After installing stack
For stack to work properly, you need to manually set the Maxima version.

Go to `Site administration > Plugins > STACK` and change `Maxima version` to 5.44.0