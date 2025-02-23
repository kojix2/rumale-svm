# Rumale::SVM

[![Build Status](https://github.com/yoshoku/rumale-svm/workflows/build/badge.svg)](https://github.com/yoshoku/rumale-svm/actions?query=workflow%3Abuild)
[![Coverage Status](https://coveralls.io/repos/github/yoshoku/rumale-svm/badge.svg?branch=main)](https://coveralls.io/github/yoshoku/rumale-svm?branch=main)
[![Gem Version](https://badge.fury.io/rb/rumale-svm.svg)](https://badge.fury.io/rb/rumale-svm)
[![BSD 3-Clause License](https://img.shields.io/badge/License-BSD%203--Clause-orange.svg)](https://github.com/yoshoku/rumale-svm/blob/main/LICENSE.txt)
[![Documentation](https://img.shields.io/badge/api-reference-blue.svg)](https://yoshoku.github.io/rumale-svm/doc/)

Rumale::SVM provides support vector machine algorithms in
[LIBSVM](https://www.csie.ntu.edu.tw/~cjlin/libsvm/) and [LIBLINEAR](https://www.csie.ntu.edu.tw/~cjlin/liblinear/)
with [Rumale](https://github.com/yoshoku/rumale) interface.
Many machine learning libraries use LIBSVM and LIBLINEAR as background libraries of support vector machine algorithms.
On the other hand, Rumale implements support vector machine algorithms based on the mini-batch stochastic gradient descent method
implemented in Ruby.
Rumale::SVM adds the functions of support vector machine similar to general machine learning libraries to Rumale.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rumale-svm'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rumale-svm

## Documentation

- [Rumale::SVM API Documentation](https://yoshoku.github.io/rumale-svm/doc/)

## Usage
Download pendigits dataset from [LIBSVM DATA](https://www.csie.ntu.edu.tw/~cjlin/libsvmtools/datasets/) web page.

```sh
$ wget https://www.csie.ntu.edu.tw/~cjlin/libsvmtools/datasets/multiclass/pendigits
$ wget https://www.csie.ntu.edu.tw/~cjlin/libsvmtools/datasets/multiclass/pendigits.t
```

Training linear support vector classifier.

```ruby
require 'rumale/svm'
require 'rumale/dataset'

samples, labels = Rumale::Dataset.load_libsvm_file('pendigits')
svc = Rumale::SVM::LinearSVC.new(random_seed: 1)
svc.fit(samples, labels)

File.open('svc.dat', 'wb') { |f| f.write(Marshal.dump(svc)) }
```

Evaluate classifiction accuracy on testing datase.

```ruby
require 'rumale/svm'
require 'rumale/dataset'

samples, labels = Rumale::Dataset.load_libsvm_file('pendigits.t')
svc = Marshal.load(File.binread('svc.dat'))

puts "Accuracy: #{svc.score(samples, labels).round(3)}"
```

Execution result.

```sh
$ ruby rumale_svm_train.rb
$ ls svc.dat
svc.dat
$ ruby rumale_svm_test.rb
Accuracy: 0.835
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yoshoku/rumale-svm. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](https://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [BSD-3-Clause License](https://opensource.org/licenses/BSD-3-Clause).

## Code of Conduct

Everyone interacting in the Rumale::Svm project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/yoshoku/rumale-svm/blob/main/CODE_OF_CONDUCT.md).
