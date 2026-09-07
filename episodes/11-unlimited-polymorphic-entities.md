---
title: Unlimited polymorphic entities
teaching: 10
exercises: 20
---

::::::::::::::::::::::::::::::::::::::: objectives

- Understand the use of unlimited polymorphic entities
- Implement a data structure capable of holding arbitrary data based on polymorphic entities

::::::::::::::::::::::::::::::::::::::::::::::::::

:::::::::::::::::::::::::::::::::::::::: questions

- How does Fortran support unknown data (at compile time) types?

::::::::::::::::::::::::::::::::::::::::::::::::::

It is sometimes useful in C to be able to use a `void *` pointer,
a pointer for which there is no type-checking at compile time.
The nearest analogue in Fortran is the unlimited polymorphic
pointer.

## `class (*)` pointers

We have seen a polymorphic pointer of given class used in the context
of type extension. A more general type of pointer, an *unlimited
polymorphic* pointer can be declared as

```fortran
  class (*), pointer :: p => null()
```

This is particularly useful if a polymorphic reference of intrinsic
types (which cannot be extended) is required. For example:

```fortran
  real (real32), target  :: r32
  real (real64), target  :: r64
  real (real32), pointer :: p32 => null()
  real (real64), pointer :: p64 => null()

  class (*), pointer     :: p => null()

  p32 => r32      ! ok
  p64 => r32      ! compile-time error
  p   => r32      ! ok
  p   => r64      ! ok
```

While we cannot associate a pointer of a fixed type (`p64`) with a
target of incompatible type, we can with an unlimited polymorphic
pointer.

However, unlike the type-specific pointer, we cannot use the unlimited
polymorphic pointer in any context, e.g.:

```fortran
  p64 = 2.0d0      ! normal assignment ok
  p   = 2.0d0      ! compile-time error
```

Pointer assignments are valid

```fortran
  p   => p32
  p   => p64
```

If an unlimited polymorphic pointer is on the right-hand side of an assignment,
then the left-hand side must be a pointer to a non-extensible derived type.
E.g.,

```fortran
  p32  => p
```

is not valid, as this allows an association to an incompatible type.

### Exercise (2 minutes)

:::::::::::::::::::::::::::::::::::::::  challenge

## Compiling pointers

The accompanying code `example1.f90` has three invalid assignments
which will not compile, and one additional error. Check the compiler
messages for each.

:::::::::::::::  solution

## Solution

```bash
$ gfortran example1.f90
```

```output
example1.f90:14:2:

   14 |   p32 => r64
      |  1
Error: Different types in pointer assignment at (1); attempted assignment of REAL(8) to REAL(4)
example1.f90:19:2:

   19 |   p   = 0.0
      |  1
Error: Nonallocatable variable must not be polymorphic in intrinsic assignment at (1) - check that there is a matching specific subroutine for '=' operator
example1.f90:21:2:

   21 |   p32 => p
      |  1
Error: Data-pointer-object at (1) must be unlimited polymorphic, or of a type with the BIND or SEQUENCE attribute, to be compatible with an unlimited polymorphic target
example1.f90:24:23:

   24 |   print *, "Result ", p
      |                       1
Error: Data transfer element at (1) cannot be polymorphic unless it is processed by a defined input/output procedure
```

:::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::::

### Use of type guards

Recall that we can use a `select type` construct with appropriate type
gaurds to provide the compiler with concrete information to deal with
the dynamic type. This is appropriate for unlimited polymorphic pointers,
schematically:

```fortran
  class (*), pointer :: p

  select type (p)
    type is (real(real32))
      ! ... action for real32 ...
    type is (real(real64))
      ! ... action for real64 ...
  end select
```

## Typed allocation and sourced allocation

Unlimited polymorphic pointers may be used as actual arguments to procedures.
One relevant intrinsic case is `allocate()`. Typed allocation has a form
similar to a constructor which specifies the type:

```fortran
  allocate(type-spec :: alloc-list)
```

This allows allocations against unlimited polymorphic pointers, e.g.,

```fortran
  class (*), pointer :: p    => null()
  class (*), pointer :: r(:) => null()

  allocate(character (len = 9) :: p)
  allocate(real (real32)       :: r(7))
```

A useful step in many circumstances is to use sourced allocation:

```fortran
  class (*), pointer :: p => null()

  allocate(p, source = a)
```

which will produce a copy of `a`; `p` will take on the dynamic type of `a`.

## Exercise (20 minutes)

:::::::::::::::::::::::::::::::::::::::  challenge

## A key value pair

The accompanying template module `key_value_module.f90` provides a
derived type that is intended to store key value pairs, where the
key is a (deferred length) string, and the value is an unlimited
polymorphic pointer.

```fortran
  type, public :: key_value_t
    character (len = :), allocatable :: key
    class (*), pointer               :: val
  end type key_value_t
```

In principle, this can store values of any type.

Implement two specific constructors to establish key-value pairs for
integer and real intrinsic types (`int32` and `real32` from `iso_fortran_env`),
using `key_value_create_str()` as an example. Each should allocate appropriate memory for the key and the
value. These should overload the default structure constructor `key_value_t()`.

Implement a subroutine `key_value_print()` which uses a `select type`
construct to display the current type, key and value of the three
different data types.

To be complete, implement a routine to release the resources associated
with a `key_value_t`. We could use type-bound procedures for these
last two operations, but it's not really necessary in this context.

The accompanying program has some examples to act as a test.


:::::::::::::::  solution

## Solution

The constructors for `int32` and `real32` could look like

```fortran
  function key_value_create_i32(key, ivalue) result(kv)

    character (len = *), intent(in) :: key
    integer (int32),     intent(in) :: ivalue
    type (key_value_t)              :: kv

    kv%key = trim(key)
    allocate(kv%val, source = ivalue)

  end function key_value_create_i32
```

and

```fortran
  function key_value_create_r32(key, rvalue) result(kv)

    character (len = *), intent(in) :: key
    real (real32),       intent(in) :: rvalue
    type (key_value_t)              :: kv

    kv%key = trim(key)
    allocate(kv%val, source = rvalue)

  end function key_value_create_r32
```

The generic interface for `key_value_t` will need to contain all three specific constructors:

```fortran
  interface key_value_t
    module procedure key_value_create_i32
    module procedure key_value_create_r32
    module procedure key_value_create_str
  end interface key_value_t
```

To print the data stored in a `key_value_t`:

```fortran
  subroutine key_value_print(kv)

    type (key_value_t), intent(in) :: kv

    select type (val => kv%val)
      type is (integer (int32))
        print *, "int32 kv ", kv%key, val
      type is (real (real32))
        print *, "real32 kv ", kv%key, val
      type is (character (len = *))
         print *, "string kv ", kv%key, val
      type is (real (real64))
         print *, "real64 kv ", kv%key, val
      class default
        print *, "value type not recognised kv", kv%key
     end select

  end subroutine key_value_print
```

Finally, to release a `key_value_t` you could do the following,
noting that memory for both the value and the key itself should
be released with `allocate()`:

```fortran
  subroutine key_value_release(kv)

    type (key_value_t), intent(inout) :: kv

    if (allocated(kv%key)) deallocate(kv%key)
    if (associated(kv%val)) deallocate(kv%val)

  end subroutine key_value_release
```

:::::::::::::::::::::::::


::::::::::::::::::::::::::::::::::::::::::::::::::

<!-- :::::::::::::::::::::::::::::::::::::::  challenge

## Assumed type (F2018)

It is possible to use a non-pointer unlimited polymorphic dummy argument
in a procedure, e.g.:

```fortran
  subroutine example(upe)

    class (*), intent(in) :: upe
    ! ...

  end subroutine example
```

This does not have the pointer attribute, but has similar constraints.
Such an entity would allow us to replace the three specific constructors
with one which took on the dynamic type of the actual argument. Try it.
Do you think it's a good idea?


:::::::::::::::::::::::::::::::::::::::::::::::::: -->

:::::::::::::::::::::::::::::::::::::::  challenge

## A dynamic list of key value pairs

It might be useful to have an expandable list of such key value pairs.
A possible implementation is also provided in the `key_value_module.f90`

The list constructor and a procedure to add a `key_value_t` are provided.
There's also a routine to print out the list contents.
What remains to be provided is a subroutine which increases the storage as
required. This should use `move_alloc()`. Have a go at providing this
subroutine.


:::::::::::::::  solution

## Solution

Your subroutine might look like the following:

```fortran
  subroutine key_value_list_reallocate(kvlist)

    ! Expand list storage (by a factor of 2)

    type (key_value_list_t), intent(inout) :: kvlist

    type (key_value_t), allocatable :: kvtmp(:)
    integer                         :: nnew

    ! The list must be initialised here ...

    if (.not. allocated(kvlist%kv)) stop "list not initialised!"

    nnew = max(1, 2*size(kvlist%kv))
    allocate(kvtmp(nnew))

    kvtmp(1:kvlist%npair) = kvlist%kv(1:kvlist%npair)
    call move_alloc(kvtmp, kvlist%kv)

  end subroutine key_value_list_reallocate
```

:::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::::



:::::::::::::::::::::::::::::::::::::::: keypoints

- Unlimited polymorphic entities provide a `void *`\-like type in Fortran
- Without determining the unlimite polymorphic entity's dynamic type, it cannot be used

::::::::::::::::::::::::::::::::::::::::::::::::::


