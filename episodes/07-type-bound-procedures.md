---
title: Type-bound procedures
teaching: 15
exercises: 15
---

::::::::::::::::::::::::::::::::::::::: objectives

- Define a type-bound procedure for a derived type
- Override a type-bound procedure for an extended type
- Add additional functionaly to extended types not present in the parent type

::::::::::::::::::::::::::::::::::::::::::::::::::

:::::::::::::::::::::::::::::::::::::::: questions

- How can we associate behaviour with types?
- How can we specialise behaviour for extended types?

::::::::::::::::::::::::::::::::::::::::::::::::::

Many languages use the term "methods" to refer to functions or
operations that are associated with particular objects.

Methods are referred to as type-bound procedures in Fortran. They
provide a mechanism to perform operations which are appropriate
for a given (dynamic) type.

## Type-bound procedures

A type-bound procedure is a fixed entity associated with the declaration
of the type, and appears after the `contains` statement in the definition.
For example, consider again the simple `object_t`. Say we wished to add
a function to compute the volume of an object:

```fortran
  type, public ::object_t
    ! ... components ...
  contains
    ! ... procedure bindings ...
    procedure, pass :: volume => object_volume
  end type object_t
```

The `pass` attribute specified in the procedure binding
indicates that the object to which the procedure is bound will be
passed as the first argument of the call of the type-bound
procedure. This argument is called the *passed object dummy
argument*.

:::::::::::::::::::::::::::::::::::::::::  callout

## Type-bound procedures

Note there is no `pointer` attribute: this is a *type-bound* procedure.


::::::::::::::::::::::::::::::::::::::::::::::::::

We must then provide the corresponding function:

```fortran
  function object_volume(self) result(volume)

    class (object_t), intent(in) :: self
    real                         :: volume

    ! ...

  end function object_volume
```

:::::::::::::::::::::::::::::::::::::::::  callout

## Type-bound procedures are polymorphic

Where we might expect to see a `type` declaration for
the dummy argument (`self`), this has been replaced by `class`.
This is to allow that the call may be made in a context in
which the type has been extended, i.e., `class` permits polymorphism.


::::::::::::::::::::::::::::::::::::::::::::::::::

To invoke the new type-bound procedure, e.g.:

```fortran
  type (object_t) :: a = object_t()

  print *, "Volume is ", a%volume()
```

Here, the declaration of `a` remains `type` rather than `class`.
There is no polymorphism involved at this point. The object `a`
in this context is associated with the passed object dummy
argument (`self`).

### Exercise (5 minutes)

:::::::::::::::::::::::::::::::::::::::  challenge

## Type-bound procedures

Using the template `object_type.f90` add the type-bound procedure `volume()`
in the `object_t` type (only). Provide an implementation which sets the
volume to zero. Using the accompanying program `example1.f90` check you
can call the new `volume()` procedure for an `object_t`.

```bash
$ ftn object_type.f90 example1.f90
```

:::::::::::::::  solution

## Solution

The `object_t` type declaration should now look like

```fortran
type, public :: object_t
  real :: rho  = 1.0       ! density
  real :: x(3) = 0.0       ! position of centre of mass
contains
  procedure, pass :: volume => object_volume
end type object_t
```

and the module should now contain

```fortran
function object_volume(self) result(volume)

  class (object_t), intent(in) :: self
  real                         :: volume

  volume = 0.0

end function object_volume
```

:::::::::::::::::::::::::

Can you also use the same type-bound procedure for the sub-type
`sphere_t`?

:::::::::::::::  solution

## Solution

Yes, as a derived type of `object_t`, objects of type `sphere_t` can call their methods.
Does always returning `volume()=0` make sense for a `sphere_t`?

:::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::::

## Overriding a specific procedure

Types which extend a base type will inherit type-bound procedures from their
parent. If we wish to relate a different volume computation with a given
object type, we may *override* the `object_volume()` implementation with a
new implementation.

This can be done by merely re-declaring the procedure binding in the extending
type with the same name, e.g.,:

```fortran
  type, extends(object_t), public :: sphere_t
    ! ...
  contains
    procedure, pass, non_overridable :: volume => sphere_volume
  end type sphere_t
```

Here, the `non_overridable` attribute to the binding specifies that the same
name cannot be further overridden by types which extend `sphere_t`.

An overriding procedure must have exactly the same interface as the relevant
procedure in the parent type, bar the type of the object reference itself.

### Exercise (5 minutes)

:::::::::::::::::::::::::::::::::::::::  challenge

## Overriding type-bound procedures

Check you can add this specific function in the `sphere_t` type. Re-run the
`example1.f90` to check that objects of different type obtain an appropriate
result.

:::::::::::::::  solution

## Solution

Define an appropriate function for computing the volume of a sphere

```fortran
function sphere_volume(self) result(volume)

  class (sphere_t), intent(in) :: self
  real                         :: volume

  volume = (4.0/3.0)*(4.0*atan(1.0))*self%a**3

end function sphere_volume
```

and bind this to the `sphere_t` type

```fortran
type, extends(object_t), public :: sphere_t
  real :: a = 1.0          ! radius
contains
  procedure, pass, non_overridable :: volume => sphere_volume
end type sphere_t
```

:::::::::::::::::::::::::

What happens if you try to override the `volume()` procedure in the
`charged_sphere_t` having declared it `non_overridable`?

:::::::::::::::  solution

## Solution

The compiler prevents redefinition of the `non_overridable` bound procedure.

```bash
$ gfortran -c object_type.f90
```

```output
object_type.f90:23:14:

   23 |      procedure, pass :: volume => charged_sphere_volume
      |              1
Error: 'volume' at (1) overrides a procedure binding declared NON_OVERRIDABLE
```

:::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::::

## Binding attributes

The form of the type-bound procedure definition in this context is:

```fortran
  procedure [, binding-attr-list] :: type-bound-name [ => specific-name ]
```

where there is a comma-separated list of attributes which may include

1. One of `public` or `private` indicating scope;
2. `non_overridable` indicating this `type-bound-name` may not be
   re-defined in types which extend the current type;
3. `pass` or `nopass`.

:::::::::::::::::::::::::::::::::::::::::  callout

## Passing `self`

The default is that type-bound-procedure receives the *passed object dummy
argument* as the first dummy argument. There is an optional argument

```fortran
  pass [ (arg) ]
```

which can be used to specify which dummy argument is associated with the
invoking object (required if it's not the first dummy argument).


::::::::::::::::::::::::::::::::::::::::::::::::::

## Generic type-bound procedures

If one wishes to overload type-bound procedures, an additional step is
required:

```fortran
  type, public :: my_type
    ! ...
  contains
    procedure, pass :: add_real32
    procedure, pass :: add_real64
    generic, public :: add => add_real32, add_real64
  end type my_type
```

Here, the single generic name `add` is intended to be used, and must
be associated with distinguishable alternatives.
As before, this may be used for assignment, operators, generic names, or
derived type i/o.

## Procedure pointer as type component

It is possible to declare a type which has a procedure pointer as a
*component*:

```fortran
  type, public :: my_pp_t
    procedure (interface_pp), pointer :: p
  end type my_pp_t
```

:::::::::::::::::::::::::::::::::::::::::  callout

## Instance data

Such a procedure pointer is part of the data associated with an instance
of a type. Different instances of the object may contain pointers to
different procedures as the value is determined at run time. Note that
an interface definition may be required in this context.


::::::::::::::::::::::::::::::::::::::::::::::::::

## Exercise (5 minutes)

:::::::::::::::::::::::::::::::::::::::  challenge

## Computing the mass of a sphere

Add an extra type-bound procedure to the `sphere_t` to compute the sphere's
mass using the density and the type-bound `volume()` function. Check this
produces a reasonable result.

Check that this works for the `charged_sphere_t` too.

:::::::::::::::  solution

## Solution

As before, define an appropriate function to compute the sphere mass

```fortran
function sphere_mass(self) result(mass)

  class (sphere_t), intent(in) :: self
  real                         :: mass

  mass = self%rho*self%volume()

end function sphere_mass
```

and bind this to the `sphere_t` type

```fortran
type, extends(object_t), public :: sphere_t
  real :: a = 1.0          ! radius
contains
  procedure, pass, non_overridable :: volume => sphere_volume
  procedure, pass                  :: mass   => sphere_mass
end type sphere_t
```

Note that the new procedure reuses the `volume()` computation defined previously.

:::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::::



:::::::::::::::::::::::::::::::::::::::: keypoints

- Type-bound procedures allow Fortran objects to implement behaviour
- Redefining type-bound procedures allows behaviour to be specialised
- Types can prevent extended types from redefining type-bound procedures
- Generic type-bound procedures enable generic methods on types

::::::::::::::::::::::::::::::::::::::::::::::::::


