---
title: Type parameters
teaching: 15
exercises: 15
---

::::::::::::::::::::::::::::::::::::::: objectives

- Understand the use of type parameters in user-defined types.

::::::::::::::::::::::::::::::::::::::::::::::::::

:::::::::::::::::::::::::::::::::::::::: questions

- How to implement user-defined types with `kind`s, like intrinsic types?

::::::::::::::::::::::::::::::::::::::::::::::::::

## Type parameters for intrinsic types

We have seen type parameters (kind type parameters) for intrinsic types:

```fortran
  use iso_fortran_env
  ...
  integer (int32) :: i32
```

This provides a way to control, parametrically, the actual data type
associated with the variable. Such parameters must be known at compile
time.

There are all so-called deferred parameters, such as the length of a
deferred length string

```fortran
  character (len = :), allocatable :: string
```

The colon indicates the length is deferred.

## Parameterised derived types

These features may be combined in a parameterised type definition, e.g.:

```fortran
type, public :: my_array_t(kr, nlen)
  integer, kind :: kr                ! kind parameter
  integer, len  :: nlen              ! len parameter
  real    (kr)  :: data(nlen)
end type my_array_t
```

The type parameters must be integers and take one of two roles: a `kind`
parameter, which is used in the place of kind type parameters, and a
`len` parameter, which can be used in array bound declaration or a length
specificaition. A `kind` parameter must be a compile-time constant, but a
length parameter may be deferred until run time.

The extra components act as normal components in that they may have a
default value specified in the declaration, and may be accessed at run
time via the component selector `%` in the usual way.

For example declaration of a variable of such a type might look like:

```fortran
  ! ... establish len_input ...

  type (my_array_t(real32, len_input)) :: a
```

Such a parameterised type may have a dummy argument associated with an
actual argument via a dummy argument declaration, e.g.,

```fortran
  type (my_array_t(real32, nlen = *)), intent(in) :: a
```

cf.

```fortran
  character (len = *), intent(in) :: str
```

A pointer declaration of this type would use the deferred notation
with the colon:

```fortran
  type (my_array_t(real32, nlen = :)), pointer p => null()
```

Here, an (optional) keyword has been used in the parameter list.

:::::::::::::::::::::::::::::::::::::::  challenge

## Example

The example code `example1` illustrates how a parameterised type can be defined and used:

```fortran
program example1

  use iso_fortran_env
  implicit none

  type :: my_array_t(kr, nlen)
    integer, kind :: kr
    integer, len  :: nlen
    real (kr)     :: data(nlen)
  end type my_array_t

  integer :: kr
  integer :: nlen
  type (my_array_t(kr = real64, nlen = 1000)) :: a

  print *, "kind a", a%kr
  print *, "nlen a", a%nlen

  write (*, "(a)", advance = "no") "nlen: "
  read (*, *) nlen

  call defer_me(nlen)

contains

  subroutine defer_me(nlen)

    integer, intent(in) :: nlen
    type (my_array_t(kr = real32, nlen=nlen)) :: b

    print *, "Length   ", b%nlen
    print *, "Shape    ", shape(b%data)

  end subroutine defer_me

end program example1
```

The `kind` of the data held by `my_array_t%data` must be known at compile time, but the `len` of
the array can be set dynamically as shown by `defer_me()`.
You can convince yourself of this by compiling and running `example1.f90` which will allow you to
pass the array length at runtime.


::::::::::::::::::::::::::::::::::::::::::::::::::



:::::::::::::::::::::::::::::::::::::::: keypoints

- The `kind` of a user-defined type must be known at compile time (as for intrinsic types)

::::::::::::::::::::::::::::::::::::::::::::::::::


