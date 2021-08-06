# cloud-init-scripts
For automatically setting up a moodle virtual machine running ubuntu using multipass and cloud-init.

[Documentation]()

## Status on scripts
|       | cloud-init | cloud-init-dns-challenge | cloud-init-http-challenge |
|------:|:----------:|:------------------------:|:-------------------------:|
| works |      ✅     |             ❌            |             ❌             |

## After installing stack
For stack to work properly, you need to manually set the Maxima version.

Go to `Site administration > Plugins > STACK` and change `Maxima version` to 5.44.0