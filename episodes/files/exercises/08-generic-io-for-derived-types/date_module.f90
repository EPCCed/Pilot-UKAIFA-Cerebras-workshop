module date_module

  ! A module which defines a simple date type, and overrides the
  ! default formatted write.

  implicit none

  type :: my_type
     integer :: day = 0
     integer :: month = 0
     integer :: year = 0
  end type my_type

  ! Define some months, so we can produce formats like "12 Dec 2022"
  character (len = 3), dimension(12), parameter :: months = &
       [character (len = 3) :: "Jan", "Feb", "Mar", "Apr", "May", "Jun", &
                               "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"  ]

end module date_module
