---
title: Generic input/output for derived types
teaching: 10
exercises: 20
start: yes
---

::::::::::::::::::::::::::::::::::::::: objectives

- Understand how types are written/read by default
- Be able to write a custom type-bound writer/reader for generic I/O

::::::::::::::::::::::::::::::::::::::::::::::::::

:::::::::::::::::::::::::::::::::::::::: questions

- How can we customise the writing/reading of defined types?

::::::::::::::::::::::::::::::::::::::::::::::::::

## Default input/output

List-directed output for derived types can be used to provide a default
output in which each component appears in order, schematically:

```fortran
  type (my_type) :: a
  ! ...
  write (*, fmt = *) a
```

will write out all the components with some default format for the given
components.

Alternatively, if we know the components, we could write out each component
separately with an appropriate format

```fortran
  write (*, fmt = "(i4)")   a%int1
  write (*, fmt = "(f5.3)") a%real1
```

If we wish to control the output format, without needing to write each component individually, we
can customise the I/O using type-bound procedures.

## Non-default input/output

A facility for the user to specify the behaviour of input/output via
an edit descriptor is provided by means of a type-bound procedure.

For formatted i/o, a special `dt` edit-descriptor exists, of the form:

```fortran
  dt[iodesc-string][(v-list)]
```

where the `iodesc-string` is a string, and the v-list is a series of
integers. For example, we may have

```fortran
  dt" my-type: "(2,14)
```

The `iodesc-string` string and `v-list` array of integers will re-appear
as arguments to a type-bound procedure which must be provided by the
programmer.

The following generic procedures may be defined for read or write actions:

```fortan
   read (formatted)
   read (unformatted)
   write (formatted)
   write (unformatted)
```

These provide a mechanism to define a procedure with the relevant interface

1. a `formatted` interface for formatted i/o;
2. an `unformatted` interface to specify unformatted i/o.

The relevant procedure would then be called if an item of that type appeared
in the io list for a `read()` or a `write()` statement.

## Interfaces

### Unformatted output

If we consider the type `my_type`, the unformatted output implementation
requires

```fortran
   subroutine my_type_unformatted_output(self, unit, iostat, iomsg)

     class (my_type),     intent(in)    :: self    ! object
     integer,             intent(in)    :: unit    ! Fortran unit number
     integer,             intent(out)   :: iostat  ! error condition
     character (len = *), intent(inout) :: iomsg   ! error message

     ! ... implementation ...

  end subroutine my_type_unformatted_output
```

The `iostat` and `iomsg` variables take on their usual meaning in the context
of `write()`.
The `iostat` variable is zero on success, but should take a positive value if
an error occurs. If `iostat` is non-zero, `iomsg`
should contain a short message for the user on the reason for the error.

For input the only difference is that the passed object dummy argument should
be of `intent(inout)`.

### Formatted output

The formatted case includes the addition of `iodesc-string` and `v-list`
arguments:

```fortran
 subroutine my_type_write_formatted(self, unit, iotype, vlist, iostat, iomsg)

    class (my_type),     intent(in)    :: self
    integer,             intent(in)    :: unit
    character (len = *), intent(in)    :: iotype       ! "DT my-type: "
    integer,             intent(in)    :: vlist(:)     ! (2,14)
    integer,             intent(out)   :: iostat
    character (len = *), intent(inout) :: iomsg

    ! ... process arguments to give required output to unit number ...
    ! iotype is "LISTDIRECTED" for list directed io
    ! iotype is "DTdesc-string" for dt edit descriptor
    ! ...
    ! ... write (unit = unit, fmt = ...)  components ...

    ! iostat and iomsg should be set if there is an error

end subroutine my_type_write_formatted
```

Both parts of the `dt` edit descriptor are optional in the format
specification. If the `iodesc-string` is missed, the corresponding
dummy argument `iotype` is of length zero; if the `v-list` is
omitted, then `vlist` has size zero.

Again, the only difference for input is the intent of the passed
object dummy argument, which must be `intent(inout)`.

## Type-bound procedures

The two procedures above should be declared as generic type-bound procedures

```fortran
type, public :: my_type
  ! ... components ...
contains
  procedure :: my_type_write_formatted
  procedure :: my_type_write_unformatted
  generic   :: write(formatted) => my_type_write_formatted
  generic   :: write(unformatted) => my_type_write_unformatted
end type my_type
```

Some care may be required to write a robust set of procedures handling
the different formatted and unformatted cases.

No additional file operations involving the specified unit number are
allowed in the type-bound procedures. Procedures for reading must only
invoke `read()` and procedures for writing only invoke `write()`.

## Exercise (20 minutes)

:::::::::::::::::::::::::::::::::::::::  challenge

## Implementing generic I/O

Try implementing the generic `write(formatted)` procedure for the following
type:

```fortran
  type, public :: my_date
    integer :: day = 1        ! day 1-31
    integer :: month = 1      ! month 1-12
    integer :: year = 1900    ! year
  end type my_date
```

First, try list directed I/O: the format we would like is `dd/mm/yyyy` for
`01/12/1999` for 1st December 1999.

A program `date_program.f90` and module `date_module.f90` template are provided.

:::::::::::::::  solution

## Solution (list directed)

First we implement a type-bound procedure for the date object that will print it in `dd/mm/yyyy` format

```fortran
subroutine write_my_type(self, unit, iotype, vlist, iostat, iomsg)

  class (my_type),     intent(in)    :: self
  integer,             intent(in)    :: unit
  character (len = *), intent(in)    :: iotype
  integer,             intent(in)    :: vlist(:)
  integer,             intent(out)   :: iostat
  character (len = *), intent(inout) :: iomsg

  character (len = *), parameter :: dfmt = "(i2.2,'/',i2.2,'/',i4)"
  iostat = 0   ! we will assume no errors occur (iomsg is unchanged)

  write(unit, fmt = dfmt, iostat = iostat) self%day, self%month, self%year

end subroutine write_my_type
```

where the format string `dfmt` controls the formatting.
You should be able to confirm this works with the `date_program`.

:::::::::::::::::::::::::

Then try adding the `dt` edit descriptor to allow some more flexibility. For
example, a `vlist` of 3 integers might control the width of the fields for
each part of the date. This requires constructing an appropriate format string.

:::::::::::::::  solution

## Solution (edit descriptor)

Extending our earlier solution we can handle both the list directed, and the format descriptor cases

```fortran
if (iotype == "LISTDIRECTED") then
   write(unit, fmt = dfmt, iostat = iostat) self%day, self%month, self%year
else
   ! A dt-style format
   ! We will only consider the case of vlist(3)
   if (size(vlist) == 3) then
     block
       character (len = 20) :: userfmt
       write (userfmt, "(a,i1,a,i2,a,i1,a)") &
            "(i", vlist(1), ",a", vlist(2), ",i", vlist(3), ")"
       write(unit, userfmt, iostat = iostat) &
            self%day, months(self%month), self%year
     end block
   else
     ! Handle other conditions; we will just use the default format
     write (unit, dfmt, iostat = iostat) self%day, self%month, self%year
   end if
end if
```

using the default list directed format as a fallback.
The `userfmt` format string controls the display of the date, try changing some of the widths passed.

:::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::::



:::::::::::::::::::::::::::::::::::::::: keypoints

- Defined types can control how they are printed using type-bound procedures

::::::::::::::::::::::::::::::::::::::::::::::::::


