---
title: Interfaces and overloading
teaching: 10
exercises: 35
---

::::::::::::::::::::::::::::::::::::::: objectives

- Understand how to define generic interfaces, overload operators and define new names.
- Understand generic interface resolution and potential pitfalls.

::::::::::::::::::::::::::::::::::::::::::::::::::

:::::::::::::::::::::::::::::::::::::::: questions

- How are interfaces used for generic programming?

::::::::::::::::::::::::::::::::::::::::::::::::::

The `interface` block has three different forms in Fortran: it may define an
*abstract* interface, a *generic* interface, or a *specific* interface.

In this section, we will look at generic interfaces. Generic is the term
which describes overloading in Fortran.

## Generic interfaces

The formal description of an interface block in the generic context is

```fortran
interface generic-spec
  [ interface-specification ] ...
end interface generic-spec
```

The `generic-spec` has a number of different possible forms:

- `assignment (=)` for assignment
- a generic procedure name
- `operator (defined-operator)` for an operator
- a derived type i/o operation

We have seen an example of this type of interface in the  context of
overloading assignment, e.g.,

```fortran
interface assignment (=)
  module procedure :: my_assignment
end interface assignment (=)
```

There are one or more `interface-specification` entries which can take
different forms. As we will usually expect to place interface definitions
in a module along with the relevant procedure definitions,
the `interface-specification` will often involve one or more
`module procedure` statements of the form

```fortran
  [ module ] procedure [ :: ] specific-procedure-list
```

The `module` in `module procedure` in the interface block is
optional: we could use external procedures. However, it may be most
natural to place the interface in the relevant module. The procedure
interface must be available in either form.

### Generic assignment

We have seen an example of overloading assignment in the previous section:

```fortran
interface assignment (=)
  module procedure :: my_assignment
end interface assignment (=)
```

In this context, the procedure must be a subroutine (not a function) with
exactly two non-optional arguments. To prevent ambiguity, the first argument
must correspond to the left-hand side of the assignment and have
`intent(inout)` or `intent(out)`, while the second argument must represent
the right-hand side of the assignment and have `intent(in)`.

Redefining assignment between intrinsic types is not allowed, including
redefining conforming array assignments. It is possible to define
assignment between an intrinsic type and a derived type. For example,
using the `my_array_t` again from the previous section:

```fortran
subroutine my_assignment_from_int(a, ival)

  type (my_array_t), intent(inout) :: a
  integer,           intent(in)    :: ival

  a%values(:) = ival

end subroutine my_assignment_from_int
```

In this way, one can have a number of different procedures which overload the
assignment: they are generic.

If the right-hand side is an expression, one can consider the assignment as
being replaced by a call to the subroutine, with the second argument being
the expression enclosed in parentheses (the right-hand side).

If an *elemental* subroutine is provided as a generic interface, both scalar
and array assignments can be performed. Particular combinations
of ranks may be specified (in which case intrinsic assignment remains
available for other combinations).

### Generic procedures

A generic procedure allows one to associate a generic name with one or more
specific procedures.

```fortran
interface generic-name
  module procedure :: specific-prcedure-list
end interface generic-name
```

The `specific-procedure-list` can be a comma-separated list of
different implementations, or one may add new implementation on
different lines. For example,

```fortran
interface my_generic_name
  module procedure :: my_real32_implementation
  module procedure :: my_real64_implementation
end interface my_generic_name
```

We are required to implement subroutines which are
*distinguishable* by their arguments.

:::::::::::::::::::::::::::::::::::::::::  callout

## Generic procedure kinds

A `procedure-list` must consist of
either all subroutines or all functions: there cannot be a mix of
subroutines and functions.


::::::::::::::::::::::::::::::::::::::::::::::::::

### Distinguishable procedures

In order that the compiler can identify unambiguously the appropriate
specific implementation based on the actual arguments at the point of
invocation, the signatures of a generic procedure must be distinguishable.

:::::::::::::::::::::::::::::::::::::::::  callout

## Distinguishing dummy arguments

Individual pairs of dummy arguments are distinguishable:

- if both are data objects and have different types, kind type parameters
  or ranks;
- if one is allocatable and the other is a pointer;
- if one is a procedure and the other is a data object.
  

::::::::::::::::::::::::::::::::::::::::::::::::::

Together, the set of non-optional arguments in each case
must be distinguishable. Note that the order may not be counted upon if the
dummy arguments in the two procedures have the same name, as one can always call using keywords
at the point of invocation, e.g.,

```fortran
  call my_subroutine(arg2 = y, arg1 = x)
```

The presence or absence of a pointer attribute in the dummy argument is not
enough to disambiguate a call; a pointer actual argument can be associated
with a dummy argument which is a non-pointer data object.

### Example (10 minutes)

:::::::::::::::::::::::::::::::::::::::  challenge

## Constructor overloading

Looking again at our `my_array_t` example, check that you can overload the
default structure constructor `my_array_t()` using the existing function
`my_array_allocate()`. A new version of the module and program are available
in the `exercises/05-interfaces-overloading` directory (or you can keep your existing one).

```bash
$ ftn my_array_type.f90 example1.f90
```

:::::::::::::::  solution

## Solution 1

Define a generic interface `my_array_t` that resolves to `my_array_allocate`

```fortran
interface my_array_t
   module procedure my_array_allocate
end interface my_array_t
```

The object can now be initialised as `a = my_array_t(3)` and the output should match the
original code.

:::::::::::::::::::::::::

Add a new overloaded version to the same generic name which allows us to
allocate a new array of a given size, but with the values initialised
uniformly by a scalar integer supplied as a second argument to the new
implementation. Check this works as expected.

:::::::::::::::  solution

## Solution 2

Extend the generic interface to *also* resolve to `my_array_allocate_set` when passed two
arguments.

```fortran
interface my_array_t
   module procedure my_array_allocate
   module procedure my_array_allocate_set
end interface my_array_t

contains

function my_array_allocate_set(nlen, val) result(a)

  integer, intent(in) :: nlen
  real, intent(in) :: val
  type(my_array_t) :: a

  a%nlen = nlen
  allocate(a%values(nlen))
  a%values(:) = val

end function my_array_allocate_set
```

Calling `a = my_array_t(4, 5.0)` should now (re)allocate `a` with four entries, each set to
`5.0`.

:::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::::

### Example (5 minutes)

:::::::::::::::::::::::::::::::::::::::  challenge

## Different order, same arguments

The following is an edge-case which will not compile, as the dummy arguments
of the two subroutines in the generic interface are ambiguous.

```bash
$ ftn -c example2.f90
```

There's actually a simple solution to the problem. Can you see what it is?
(Think about the keyword argument case.)

:::::::::::::::  solution

## Solution

Because the arguments are named the same, using keyword arguments the two implementations cannot
be distinguished by argument order. To resolve this we can simply rename one of the arguments in
one of the implementations, e.g.

```fortran
subroutine my_print_b(i, r)

  integer, intent(in) :: i
  real,    intent(in) :: r

  print *, "integer real32 ", i, r

end subroutine my_print_b
```

:::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::::

## Overloading operators

It is possible to overload an intrinsic operator (such as `+`), or define a
new name for an operation. The intrinsic operators include arithmetic
operators `+, -, *, /` etc, logical operators including `.not., .or.`,
and relational operators including `==, <, <=`. The choice of name or
symbol may depend on how meaning is ascribed to the operation.

To do so, one must provide a function (not a subroutine) taking exactly
one argument for unary operations such as negation, or exactly two
arguments for binary operations such as multiplication. The arguments
must be `intent(in)` in both cases. The arguments cannot be optional.

One cannot overload operations for intrinsic types. They are only relevant
for combinations of derived types, or derived types and intrinsic types.

For example, if we had two types

```fortran
type (date_time_t)      :: now       ! a date and time
type (time_interval_t)  :: dt        ! interval in seconds
```

one might wish to overload the meaning of `+` to allow an interval to be
added to a date. This could be done as follows, assume we have a module
which makes available both types:

```fortran
interface operator (+)
  module procedure :: add_interval_to_date_time
end interface operator (+)
```

We would then have to supply the function

```fortran
function add_interval_to_date_time(date, dt) result(newdate)

  type (date_time_t),     intent(in) :: date
  type (time_interval_t), intent(in) :: dt
  type (date_time_t)                 :: newdate

  ! ... details of implementation ...

end function add_interval_to_date_time
```

An expression of the form

```fortran
now + dt
```

would then be replaced by the result of the function, which in this case
is of type `date_time_t`.

The order is significant here. The left-hand operand of the operation
corresponds to the first dummy argument, and the right-hand operand
corresponds to the second dummy argument. So one could not have
`dt + now`.

One could, equivalently, invoke the function directly:

```fortran
  type (date_time_t) :: newdate
  ...
  newdate = add_interval_to_date(now, dt)
```

:::::::::::::::::::::::::::::::::::::::::  callout

## Caution

This is a (deliberately) somewhat contentious example. It raises a number
of general concerns about the approach:

1. If operations involve a single type, the operands are interchangeable,
   and a limited number of functions is required.
2. If operations involving even one defined type and one intrinsic type
   are required, then the number of possible operations can quickly
   become quite large (without asking the question whether specific
   operations have meaning).

So it can be quite difficult to achieve a complete, consistent, and
transparent set of operations for any new type.


::::::::::::::::::::::::::::::::::::::::::::::::::

### Using a non-intrinsic name

We could equally define a new name

```fortran
  interface operator(.add.)
    module procedure add_interval_to_date
  end interface operator (.add.)
```

in which case we would write

```fortran
   newtime = now .add. dt
```

A new name must be of this form (having `.` at start and finish) and must
not be either `.true.` or `.false.`.

If one limits the choice to the intrinsic operator names, the precedence of
the different operations is the same, e.g., the precedence of `*` is always
greater than `+`. If using new names, precedence in complex expressions may
need to be established via parentheses.

### Exercise (20 minutes)

:::::::::::::::::::::::::::::::::::::::  challenge

## Dot and cross products

Write a module which defines a type to hold a 3-vector `(u_1, u_2, u_3)` where
the components are integers. Define an operator `.x.` which
computes the cross product of two vectors, being

$\mathbf{u} \times \mathbf{v} = (u_2 v_3 - u_3 v_2, u_3 v_1 - u_1 v_3, u_1 v_2 - u_2 v_1).$

This should also allow a vector triple product such as

$\mathbf{u} \times \left( \mathbf{v} \times \mathbf{w} \right)$

noting the order of the cross products is important.

One could also define a scalar product `.dot.`, being

$\mathbf{u} \cdot \mathbf{v} = u_1 v_1 + u_2 v_2 + u_3 v_3.$

Does a scalar triple product

$\mathbf{u} \cdot \mathbf{v} \times \mathbf{w}$

work correctly without parentheses?

A template is provided

```bash
$ ftn example3.f90 my_vector_type.f90
```

where the example program has a number of suggestions to check the results.

:::::::::::::::  solution

## Solution

```fortran
  interface operator(.dot.)
     module procedure dot_prod
  end interface operator(.dot.)

  interface operator (.x.)
     module procedure cross_prod
  end interface operator (.x.)

contains

  module function dot_prod(a, b) result(d)
    type(my_vector_t), intent(in) :: a, b
    integer :: d

    d = a%x * b%x + a%y * b%y + a%z * b%z
  end function dot_prod

  module function cross_prod(a, b) result(z)
    type(my_vector_t), intent(in) :: a, b
    type(my_vector_t) :: z

    z%x = a%y * b%z - b%y * a%z
    z%y = -(a%x * b%z - b%x * a%z)
    z%z = a%x * b%y - b%x * a%y
  end function cross_prod
```

The scalar triple product requires parentheses as evaluating the dot product would return a
scalar as the first argument to the cross product (incorrect).

:::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::::



:::::::::::::::::::::::::::::::::::::::: keypoints

- Interfaces allow us to write generic, high-level code.
- Designing a generic interface requires care, particularly for generic operators.

::::::::::::::::::::::::::::::::::::::::::::::::::


