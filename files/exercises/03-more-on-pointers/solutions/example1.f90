program example1

  implicit none

  integer, target  :: a(10)
  integer, pointer :: p(:)
  integer :: i

  p => a(2:10:2)
  a = [ (i, i = 1, 10) ]

  ! print pointer lower bound lbound()
  print *, "Lower bound: ", lbound(p) ! => 1

  ! print pointer upper bound ubound()
  print *, "Upper bound: ", ubound(p) ! => 5

  ! check size and elements
  print *, "Size: ", size(p) ! => 5
  print *, "p(4) = ", p(4)   ! => 8

end program example1
