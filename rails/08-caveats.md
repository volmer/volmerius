---
tags: rails
layout: rails-page
title: Caveats
date: 2021-02-01
---

No design is perfect. The architecture proposed in this document provides a good
starting point for sustainable, long term development in Rails, but by no means
it gives answers to all possible cases and complications that could arise along
the way. It is crucial for developers to always keep in mind the principles of
object oriented design while adopting this architecture, such as keeping objects
small and simple, with thoughtful introduction of indirection when necessary.

This section exemplifies complications that might arise from the use of the
patterns here prescribed, with suggestions on how to address these limitations
when possible.

## Complex Actions

Actions are designed to be the centerpieces of business logic, coordinating all
the steps required to process a user request. For that reason, they are the
objects with the highest tendency to become big, complex, and coupled with many
other structures. Actions are by definition aware of Inputs, Repositories,
Models, Jobs, and many other objects from the system. It won’t take too long for
Actions to lean towards accumulating nested code, conditionals, and many other
code smells.

Actions are such magnets for complexity because of their very nature of being
the core units of business logic. After all, the business logic layer of any app
is modified far more often than any other layer; the churn of business logic
code is incredibly high when compared to the rest of the system, and there is no
escape for that. This complexity can be minimized through refactorings and
indirection, but apps will always need to have business logic entry points where
everything is tied together.

In order to avoid excessive complexity in Actions, it is crucial to model these
objects atomically enough so they can be specialized to handle very particular
requests in isolation. Designing simpler Actions might impact even the routes
and controllers design. For example, instead of having one big Action that
receives many optional arguments, it is preferable to split it in different
Actions (and therefore different endpoints) for each specific case.

Actions can also collaborate with auxiliary objects that handle certain aspects
of business logic beyond Repositories and Jobs. Each app might require
additional objects and layers so the burden in Actions is reduced. For instance,
the specifics of crafting outgoing HTTP requests to services might be deferred
to service objects that play that role, and Actions can simply instantiate and
send messages to them.

## Duplication in Actions

Actions might end up sharing similarities to other Actions, leading to an excess
of duplicated code in these objects. Given that by design Actions are not
allowed to interact with each other, and also given that there can only be one
Action for each request, it might get tricky to remove the repeated logic.

First of all, it is important to emphasize that not all duplication needs to be
removed in order to achieve a sustainable architecture. More often than not,
attempts to remove duplication lead to a poor, complex design and an overall
worse code than the previous duplicated code. Developers feel the urge to remove
every and single duplication as a deceitful instinct of fixing a possible code
smell. The truth, however, is that duplication is much easier to understand and
change than abstractions that are poorly designed. Before addressing any
duplication, the best course of action is to wait until the duplicated logic is
referenced too many times, copied at least three times over.

Once the duplication becomes a real concern, the code can be refactored by
extracting the repeated logic into specialized objects Actions can interact
with. A particular case is when the duplication happens around composing the
Result object. An app might introduce a new layer of Result composers for that
purpose that Actions can rely on and delegate that process to.

## Testing Actions

The topic of testing is not covered in this document, but a word is needed
regarding testing Actions. Actions don’t need to be tested through unit tests.
Instead, these objects’ behaviours should be asserted indirectly through proper
integration test coverage.

Given that Actions represent an entire feature or use case, developers might be
tempted to end up writing unit tests that are actually integration tests in
disguise. For example, a unit test for the Create Article Action might end up
asserting that a Record is persisted. This test is not a unit test, since the
code in the Action is completely decoupled from the database or from Active
Record itself. Such assertions are important, but should be written as
integration or system tests.

In theory, unit testing for Actions needs to ensure that the Action is sending
the expected messages to its collaborator objects and that the Result returned
by the Action has the right values, and nothing more. This would likely require
mocking/stubbing libraries, so tests are performed fast by not actually making
network calls or database operations. Once again, this does not replace the need
for integration tests whatsoever, since only these end-to-end assertions can
ensure that the system as a whole is functional and the network of objects
behave properly in the real world.

Given that the only way to test Actions is through excessive stubbing and
mocking, and that these unit tests do not replace integration tests, writing
unit tests for Actions is an unnecessary burden. Instead, the Actions behaviours
should be asserted indirectly through proper integration test coverage.

## Validation Antipatterns

This architecture proposes the use of validation in Input objects by including
Active Model validations. By inheriting from Active Model, Inputs can have the
same well-known validation API and seamlessly integrate with view forms.

```ruby
  if input.valid?
    @article = ArticleRepository.new.create(input)
  else
    failure(input.errors)
  end
```

This approach comes with costs, however. Firstly, this choice lets Inputs
inherit the Rails antipattern of mutating objects in order to fetch validation
results. A valid object has no errors, but only until someone else asks it for
its valid state, in which it might end up populating its own errors, mutating
its own state. This is a brittle design that violates the idea of an Input
representing the user’s entries and nothing more. Worst even, this mutation
happens by calling a predicate method. Predicates, as any query method, should
simply return information about the object but not alter the state of a
subsystem.

Secondly, validation errors are represented as instances of Active Model Errors,
which is quite limited in its API. There are no standardized formats for
individual errors, which might negatively impact the design of meaningful
representation of validation messages, as seen in the GraphQL section.

Apps that face these costs might opt for not using Active Model for input
validation, but instead introduce their own Validators as collaborator objects
that Actions can invoke in order to check for the validity of Inputs. Similarly,
errors can be represented using well-defined structs with proper fields such as
messages, codes, and attribute names.

## Transactions

Database transactions guarantee that a series of steps are performed atomically,
making possible to roll them all back in case of errors. In Rails, transactions
are defined as blocks where all their database operations are committed to the
database together in case of a successful yield, or rolled back if an error is
raised.

Grouping logical steps in atomic groups with transactions is part of the
business logic layer. When the app requires transactions, there is a risk for
Actions to end up coupled with Active Record once again. In order to achieve a
sustainable architecture, however, it is important to respect the design
decision to encapsulate Active Record behind Repositories in this case as well.
Additionally, transactions are excellent candidates to be extracted into more
specialized objects.

Back to the Blog example, let’s say we don’t want to persist a comment if the
Job that delivers the notification email fails to be enqueued. This requires
grouping the Comment creation and the email notification delivery in a
transaction.

The first thing we can do is to create a method in the Repository to encapsulate
Active Record:

```ruby
class CommentRepository
  class << self
    def transaction
      ActiveRecord::Base.transaction { yield(new) }
    end
  end
end
```

We can now model our transaction as an object that executes the piece of
protected business logic that is rolled back all at once in case of errors:

```ruby
class CreateCommentTransaction
  def perform(input)
    CommentRepository.transaction do |repository|
      comment = repository.create(input)
      NewCommentEmailJob.perform_later(comment.id)
      comment
    end
  end
end
```

The Action can now simply validate the input and perform the Transaction,
remaining decoupled from Active Record, or the transaction block itself:

```ruby
class CreateCommentAction < Action
  expose :comment

  def perform(input)
    if input.valid?
      @comment = CreateCommentTransaction.new.perform(input)
    else
      failure(input.errors)
    end
  end
end
```
