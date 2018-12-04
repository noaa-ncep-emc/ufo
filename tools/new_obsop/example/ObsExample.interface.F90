! (C) Copyright 2017-2018 UCAR
!
! This software is licensed under the terms of the Apache Licence Version 2.0
! which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

!> Fortran example module for functions on the interface between C++ and Fortran
!  to handle observation operators

module ufo_example_mod_c

  use iso_c_binding
  use config_mod
  use ufo_example_mod 
  implicit none
  private

  ! ------------------------------------------------------------------------------
#define LISTED_TYPE ufo_example

  !> Linked list interface - defines registry_t type
#include "../../linkedList_i.f"

  !> Global registry
  type(registry_t) :: ufo_example_registry

  ! ------------------------------------------------------------------------------

contains

  ! ------------------------------------------------------------------------------
  !> Linked list implementation
#include "../../linkedList_c.f"

! ------------------------------------------------------------------------------

subroutine ufo_example_setup_c(c_key_self, c_conf) bind(c,name='ufo_example_setup_f90')
implicit none
integer(c_int), intent(inout) :: c_key_self
type(c_ptr),    intent(in)    :: c_conf

type(ufo_example), pointer :: self

call ufo_example_registry%setup(c_key_self, self)

call self%setup(c_conf)

end subroutine ufo_example_setup_c

! ------------------------------------------------------------------------------

subroutine ufo_example_delete_c(c_key_self) bind(c,name='ufo_example_delete_f90')
implicit none
integer(c_int), intent(inout) :: c_key_self
    
type(ufo_example), pointer :: self

call ufo_example_registry%get(c_key_self, self)

call self%delete()

call ufo_example_registry%remove(c_key_self)

end subroutine ufo_example_delete_c

! ------------------------------------------------------------------------------

subroutine ufo_example_simobs_c(c_key_self, c_key_geovals, c_obsspace, c_nobs, c_hofx, c_bias) bind(c,name='ufo_example_simobs_f90')

implicit none
integer(c_int), intent(in) :: c_key_self
integer(c_int), intent(in) :: c_key_geovals
type(c_ptr), value, intent(in) :: c_obsspace
integer(c_int), intent(in) :: c_nobs
real(c_double), intent(inout) :: c_hofx(c_nobs)
integer(c_int), intent(in) :: c_bias

type(ufo_example), pointer :: self

call ufo_example_registry%get(c_key_self, self)
call self%opr_simobs(c_key_geovals, c_obsspace, c_hofx)

end subroutine ufo_example_simobs_c

! ------------------------------------------------------------------------------

end module ufo_example_mod_c