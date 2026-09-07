program example2

  implicit none

  interface
     function array_size(a) result(isize)
       real, dimension(:), intent(in) :: a
       integer                        :: isize
     end function array_size
  end interface

  procedure (array_size), pointer :: f => array_size
  real :: a(13)

  print *, "size of a is: ", array_size(a)
  print *, "size of a is: ", f(a)

end program example2
