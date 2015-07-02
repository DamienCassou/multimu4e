[![Build Status](https://travis-ci.org/DamienCassou/multimu4e.svg?branch=master)](https://travis-ci.org/DamienCassou/multimu4e)

# multimu4e

## Summary

Facilitate the configuration of multiple accounts in mu4e

## Installing

Use [melpa](http://melpa.milkbox.net).

You may want to add something like that to your Emacs initialization
file:

```emacs
(require 'multimu4e)
(add-hook 'mu4e-compose-pre-hook #'multimu4e-set-account-in-compose)
(bind-key "C-c F" #'multimu4e-force-account-in-compose)
```

## Contributing

Yes, please do! See [CONTRIBUTING][] for guidelines.

## License

See [COPYING][]. Copyright (c) 2015 Damien Cassou.


[CONTRIBUTING]: ./CONTRIBUTING.md
[COPYING]: ./COPYING
