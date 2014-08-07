# Foreman Coding Standards
The purpose of the Foreman Coding Standards is to create a baseline for collaboration and review within various aspects of the Foreman project and community, from core code to plugins. 

Coding standards help avoid common coding errors, improve the readability of code, and simplify modification. They ensure that files within the project appear as if they were created by a single person.

## Pull requests

All pull requests need to have an associated issue in the Foreman [issue tracker](http://projects.theforeman.org/). 

Foreman's [PR processor](https://github.com/theforeman/prprocessor) will parse all pull requests, assign labels, and run tests for all major projects. 
Pull requests are always *rebased* on top of the develop branch so that the git log stays linear.

## Commit messages

Provide a brief description of the change in the first line (50 chars or less), including a issue number. 

The title must start with ```Feature #xxxx```, ```Bug #xxxx```, ```Refactor #xxxx``` so that the PR processor auto places the issue in the right category in the issue tracker.

You can use the following model:

```
Feature #9999 - lunch mars probe in V2 API.

Some collaboration between teams will be necessary to accomplish this
task. Other features, #2932 and #2933 will be closed after this. V1
changes to the API were not necessary.
```

Insert a single blank line after the first line.

Optionally, include more detailed explanatory text if necessary and wrap it to about 72 characters or so. ```git commit``` automatically wraps the text to these limits as you type in. 

Ensure the description is of the change and not the bug title, e.g. "X now accepts Y when doing Z" rather than "Z throws error"

###Notes
* Some background to justify this commit message style can be found [here](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html).
* By adding 'Refs #<issue number>' PR processor will auto add the commit to an existing issue. Usually an already closed issue, or just to add some code to a existing issue with another PR open.

## Ruby
We follow the [Ruby Style Guide](https://github.com/bbatsov/ruby-style-guide) and the [Rails 3/4 Style Guide](https://github.com/bbatsov/rails-style-guide). 

We use the following structure for models:

```
class 
extend
include
default_scope (hopefully none)
constants
attr related macros
associations
nested_attributes_for
validates
callbacks
delegations
scopes and scoped_search
other macros
class methods
instance methods
protected
private
```

####Do
* Use ```blank?``` over ```empty?``` for strings.
* Keep in mind models need to be filtered through the scope authorized.
* If you feel like you are nearly copy pasting code, please refactor.
* Raise exceptions of the type Foreman::Exception
* Write unit tests for all model methods.
* Write functional tests for all controller methods.
* Use Rails 3+ validators syntax, e.g: ```validates :name, :uniqueness => true, :presence => true```
* View templates must have an ```.html.erb``` extension.
* Make sure Mixins use ActiveSupport::Concern fully, with no class_eval, InstanceMethods etc. 
* New fields in your model must be documented in the latest version of the API if it exists.
* Ensure Apipie documentation is correct, required fields, names of parameters and HTTP methods.
* Add appropriate permissions for non-admin users and test your routes with them.
* Set ```:mark_translated: true``` in ```config/settings.yaml``` to spot missing string i18n extractions.
* Concerns and new classes are added to app/, not lib/.
* Favor ```.present?``` over ```.nil?```. Only use the latter if you are truly checking for nil, which is uncommon.
* If adding new model attributes, use scoped search definitions where appropriate.
* Virtual fields must have the option ```:only_explicit``` when added to scoped search.
* Only catch exceptions that are expected. Wrap them in Foreman::WrappedException

####Don't
* Use ```.to_sym```, ```.send```, ```eval``` or other reflection on untrusted inputs.
* Catch unexpected exceptions, or Foreman::Exception.
* Use single character variable names or abbreviations. The keyboard erosion you might save by doing that is not worth it.

### Tests
We use MiniTest::Unit syntax. 

* Use ```test 'description' do``` instead of ```def test_description```
* Use custom assertions for variable status checks, e.g: ```assert_empty variable``` instead of ```assert variable.empty?```
* Use ```:success, :not_authorized, etc...```, instead of actual HTTP status codes.
* Favor FactoryGirl over fixtures. Only use fixtures when the object is created very often throughout the test suite.

## Javascript
### Tests
## Internationalization
## Puppet
### Tests
