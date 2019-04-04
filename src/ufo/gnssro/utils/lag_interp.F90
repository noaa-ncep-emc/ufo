!> Fortran module to prepare for Lagrange polynomial interpolation.
!> based on GSI: lagmod.f90
 
module lag_interp_mod

use kinds, only: kind_real
use gnssro_mod_constants,only: zero, one

implicit none

! set default to private
private
! set subroutines to public
public :: lag_interp_const
public :: lag_interp_const_TL
public :: lag_interp_const_AD
public :: lag_interp_weights
public :: lag_interp_weights_TL
public :: lag_interp_weights_AD
public :: lag_interp_smthWeights
public :: lag_interp_smthweights_TL
public :: lag_interp_smthweights_AD


contains

subroutine lag_interp_const(q,x,n)
! Precompute the N constant denominator factors of the N-point 
! Lagrange polynomial interpolation formula.
!
! input argument list:
!   X -    The N abscissae.
!   N -    The number of points involved.
!
! output argument list:
!   Q -    The N denominator constants.
IMPLICIT NONE

INTEGER          ,INTENT(in   ) :: n
REAL(kind_real),INTENT(  out) :: q(n)
REAL(kind_real),INTENT(in   ) :: x(n)
!-----------------------------------------------------------------------------
INTEGER                      :: i,j
!=============================================================================
DO i=1,n
   q(i)=one
   DO j=1,n
      IF(j /= i)q(i)=q(i)/(x(i)-x(j))
   ENDDO
ENDDO
end subroutine lag_interp_const


!============================================================================
subroutine lag_interp_const_TL(q,q_TL,x,x_TL,n)
!============================================================================
IMPLICIT NONE

INTEGER          ,INTENT(in   ) :: n !number of points involved
REAL(kind_real),DIMENSION(n),INTENT(  out) :: q,q_TL
REAL(kind_real),DIMENSION(n),INTENT(in   ) :: x,x_TL
!-----------------------------------------------------------------------------
INTEGER                      :: i,j
REAL(kind_real)                         :: rat
!=============================================================================
DO i=1,n
   q(i)=one
   q_TL(i)=zero
   DO j=1,n
      IF(j /= i) THEN
         rat=one/(x(i)-x(j))
         q_TL(i)=(q_TL(i)-q(i)*(x_TL(i)-x_TL(j))*rat)*rat
         q(i)=q(i)*rat
      ENDIF
   ENDDO
ENDDO
end subroutine lag_interp_const_TL


!============================================================================
subroutine lag_interp_const_AD(q_AD,x,x_AD,n)
!============================================================================
IMPLICIT NONE

INTEGER          ,INTENT(in   ) :: n
REAL(kind_real),DIMENSION(n),INTENT(in   ) :: x
REAL(kind_real),DIMENSION(n),INTENT(inout) :: x_AD
REAL(kind_real),DIMENSION(n),INTENT(inout) :: q_AD
!-----------------------------------------------------------------------------
INTEGER                      :: i,j
REAL(kind_real),DIMENSION(n)            :: q
REAL(kind_real),DIMENSION(n,n)          :: jac
!=============================================================================
call lag_interp_const(q,x,n)
jac=zero
DO i=1,n
   DO j=1,n
      IF(j /= i) THEN
         jac(j,i)=q(i)/(x(i)-x(j))
         jac(i,i)=jac(i,i)-jac(j,i)
      ENDIF
   ENDDO
ENDDO
x_AD=x_AD+matmul(jac,q_AD)
end subroutine lag_interp_const_AD

!============================================================================
subroutine lag_interp_weights(x,xt,q,w,dw,n)
! Construct the Lagrange weights and their derivatives when 
! target abscissa is known and denominators Q have already 
! been precomputed
!
! input argument list:
!   X   - Grid abscissae
!   XT  - Target abscissa
!   Q   - Q factors (denominators of the Lagrange weight formula)
!   N   - Number of grid points involved in the interpolation
!
! output argument list:
!   W   - Lagrange weights
!   DW  - Derivatives, dW/dX, of Lagrange weights W
!============================================================================
IMPLICIT NONE

INTEGER          ,INTENT(IN   ) :: n
REAL(kind_real)             ,INTENT(IN   ) :: xt
REAL(kind_real),INTENT(IN   ) :: x(n),q(n)
REAL(kind_real),INTENT(  OUT) :: w(n),dw(n)
!-----------------------------------------------------------------------------
REAL(kind_real)            :: d(n),pa(n),pb(n),dpa(n),dpb(n)
INTEGER                      :: j
!============================================================================
pa(1)=one
dpa(1)=zero
do j=1,n-1
   d(j)=xt-x(j)
   pa (j+1)=pa (j)*d(j)
   dpa(j+1)=dpa(j)*d(j)+pa(j)
enddo
d(n)=xt-x(n)

pb(n)=one
dpb(n)=zero
do j=n,2,-1
   pb (j-1)=pb (j)*d(j)
   dpb(j-1)=dpb(j)*d(j)+pb(j)
enddo
do j=1,n
   w (j)= pa(j)*pb (j)*q(j)
   dw(j)=(pa(j)*dpb(j)+dpa(j)*pb(j))*q(j)
enddo
end subroutine lag_interp_weights


!============================================================================
subroutine lag_interp_weights_TL(x,x_TL,xt,q,q_TL,w,w_TL,dw,dw_TL,n)
!============================================================================
IMPLICIT NONE

INTEGER          ,INTENT(IN   ) :: n
REAL(kind_real)             ,INTENT(IN   ) :: xt
REAL(kind_real),DIMENSION(n),INTENT(IN   ) :: x,q,x_TL,q_TL
REAL(kind_real),DIMENSION(n),INTENT(  OUT) :: w,dw,w_TL,dw_TL
!-----------------------------------------------------------------------------
REAL(kind_real),DIMENSION(n)            :: d,pa,pb,dpa,dpb
REAL(kind_real),DIMENSION(n)            :: d_TL,pa_TL,pb_TL,dpa_TL,dpb_TL
INTEGER                      :: j
!============================================================================
pa(1)=one
dpa(1)=zero
pa_TL(1)=zero
dpa_TL(1)=zero

do j=1,n-1
   d(j)=xt-x(j)
   d_TL(j)=-x_TL(j)
   pa    (j+1)=pa    (j)*d(j)
   pa_TL (j+1)=pa_TL (j)*d(j)+pa(j)*d_TL(j)
   dpa   (j+1)=dpa   (j)*d(j)+pa(j)
   dpa_TL(j+1)=dpa_TL(j)*d(j)+dpa(j)*d_TL(j)+pa_TL(j)
enddo
d(n)=xt-x(n)
d_TL(n)=-x_TL(n)

pb(n)=one
dpb(n)=zero
pb_TL(n)=zero
dpb_TL(n)=zero
do j=n,2,-1
   pb    (j-1)=pb    (j)*d(j)
   pb_TL (j-1)=pb_TL (j)*d(j)+pb (j)*d_TL(j)
   dpb   (j-1)=dpb   (j)*d(j)+pb (j)
   dpb_TL(j-1)=dpb_TL(j)*d(j)+dpb(j)*d_TL(j)+pb_TL(j)
enddo
do j=1,n
   w    (j)= pa   (j)*pb (j)*q(j)
   dw   (j)=(pa   (j)*dpb(j)+dpa(j)*pb    (j))*q(j)
   w_TL (j)=(pa_TL(j)*pb (j)+pa (j)*pb_TL (j))*q(j)+pa(j)*pb(j)*q_TL(j)
   dw_TL(j)=(pa_TL(j)*dpb(j)+pa (j)*dpb_TL(j)+dpa_TL(j)*pb(j)+dpa(j)*pb_TL(j))*q(j)+ &
            (pa   (j)*dpb(j)+dpa(j)*pb    (j))*q_TL(j)
enddo
end subroutine lag_interp_weights_TL


!============================================================================
subroutine lag_interp_weights_AD(x,x_AD,xt,q,q_AD,w_AD,dw_AD,n)

!============================================================================
IMPLICIT NONE

INTEGER          ,INTENT(IN   ) :: n
REAL(kind_real)             ,INTENT(IN   ) :: xt
REAL(kind_real),DIMENSION(n),INTENT(IN   ) :: x,q
REAL(kind_real),DIMENSION(n),INTENT(INOUT) :: q_AD,x_AD,w_AD,dw_AD
!-----------------------------------------------------------------------------
REAL(kind_real),DIMENSION(n)            :: d,pa,pb,dpa,dpb
REAL(kind_real),DIMENSION(n)            :: d_AD,pa_AD,pb_AD,dpa_AD,dpb_AD
INTEGER                      :: j
!============================================================================

pa_AD=zero; dpb_AD=zero; dpa_AD=zero; pb_AD=zero
d_AD=zero

! passive variables
pa(1)=one
dpa(1)=zero
do j=1,n-1
   d(j)=xt-x(j)
   pa (j+1)=pa (j)*d(j)
   dpa(j+1)=dpa(j)*d(j)+pa(j)
enddo
d(n)=xt-x(n)
pb(n)=one
dpb(n)=zero
do j=n,2,-1
   pb (j-1)=pb (j)*d(j)
   dpb(j-1)=dpb(j)*d(j)+pb(j)
enddo
!
do j=n,1,-1
   pa_AD (j)=pa_AD (j)+ dpb(j)*q  (j)*dw_AD(j)
   dpb_AD(j)=dpb_AD(j)+ pa (j)*q  (j)*dw_AD(j)
   dpa_AD(j)=dpa_AD(j)+ pb (j)*q  (j)*dw_AD(j)
   pb_AD (j)=pb_AD (j)+ dpa(j)*q  (j)*dw_AD(j)
   q_AD  (j)=q_AD  (j)+(pa (j)*dpb(j)+dpa  (j)*pb(j))*dw_AD(j)
   pa_AD (j)=pa_AD (j)+ pb (j)*q  (j)*w_AD (j)
   pb_AD (j)=pb_AD (j)+ pa (j)*q  (j)*w_AD (j)
   q_AD  (j)=q_AD  (j)+ pa (j)*pb (j)*w_AD (j)
end do
do j=2,n
   dpb_AD(j)=dpb_AD(j)+d  (j)*dpb_AD(j-1)
   d_AD  (j)=d_AD  (j)+dpb(j)*dpb_AD(j-1)
   pb_AD (j)=pb_AD (j)       +dpb_AD(j-1)
   pb_AD (j)=pb_AD (j)+d  (j)*pb_AD (j-1)
   d_AD  (j)=d_AD  (j)+pb (j)*pb_AD (j-1)
enddo

dpb_AD(n)=zero ! not sure about it
pb_AD(n) =zero ! not sure about it

x_AD(n)=x_AD(n)-d_AD(n)
do j=n-1,1,-1
   dpa_AD(j)=dpa_AD(j)+d  (j)*dpa_AD(j+1)
   d_AD  (j)=d_AD  (j)+dpa(j)*dpa_AD(j+1)
   pa_AD (j)=pa_AD (j)       +dpa_AD(j+1)
   pa_AD (j)=pa_AD (j)+d  (j)*pa_AD (j+1)
   d_AD  (j)=d_AD  (j)+pa (j)*pa_AD (j+1)
   x_AD  (j)=x_AD  (j)       -d_AD  (j  )
enddo

end subroutine lag_interp_weights_AD


!============================================================================
subroutine lag_interp_smthWeights(x,xt,aq,bq,w,dw,n)
! Construct weights and their derivatives for interpolation 
! to a given target based on a linearly weighted mixture of 
! the pair of Lagrange interpolators which omit the respective 
! end points of the source nodes provided. The number of source 
! points provided must be even and the nominal target interval 
! is the unique central one. The linear weighting pair is 
! determined by the relative location of the target within 
! this central interval, or else the extreme values, 0 and 1, 
! when target lies outside this interval.  The objective is to 
! provide an interpolator whose derivative is continuous.
!============================================================================
IMPLICIT NONE

INTEGER            ,INTENT(IN   ) :: n
REAL(kind_real)               ,INTENT(IN   ) :: xt
REAL(kind_real),INTENT(IN   ) :: x(n)
REAL(kind_real),INTENT(IN   ) :: aq(n-1),bq(n-1)
REAL(kind_real),INTENT(  OUT) :: w(n),dw(n)
!-----------------------------------------------------------------------------
REAL(kind_real)               :: aw(n),bw(n),daw(n),dbw(n)
REAL(kind_real)               :: xa,xb,dwb,wb
INTEGER                       :: na
!============================================================================
CALL lag_interp_weights(x(1:n-1),xt,aq,aw(1:n-1),daw(1:n-1),n-1)
CALL lag_interp_weights(x(2:n  ),xt,bq,bw(2:n  ),dbw(2:n  ),n-1)
aw(n)=zero
daw(n)=zero
bw(1)=zero
dbw(1)=zero
na=n/2
IF(na*2 /= n)STOP 'In lag_interp_smthWeights; n must be even'
xa =x(na     )
xb =x(na+1)
dwb=one/(xb-xa)
wb =(xt-xa)*dwb
IF    (wb>one )THEN
   wb =one
   dwb=zero
ELSEIF(wb<zero)THEN
   wb =zero
   dwb=zero
ENDIF
bw =bw -aw
dbw=dbw-daw

w =aw +wb*bw
dw=daw+wb*dbw+dwb*bw
end subroutine lag_interp_smthWeights


!============================================================================
subroutine lag_interp_smthWeights_TL(x,x_TL,xt,aq,aq_TL,bq,bq_TL,dw,dw_TL,n)
!============================================================================
IMPLICIT NONE

INTEGER            ,INTENT(IN   ) :: n
REAL(kind_real)               ,INTENT(IN   ) :: xt
REAL(kind_real),DIMENSION(n)  ,INTENT(IN   ) :: x,x_TL
REAL(kind_real),DIMENSION(n-1),INTENT(IN   ) :: aq,bq,aq_TL,bq_TL
REAL(kind_real),DIMENSION(n)  ,INTENT(  OUT) :: dw_TL,dw
!-----------------------------------------------------------------------------
REAL(kind_real),DIMENSION(n)               :: aw,bw,daw,dbw
REAL(kind_real),DIMENSION(n)               :: aw_TL,bw_TL,daw_TL,dbw_TL
REAL(kind_real)                            :: xa,xb,dwb,wb
REAL(kind_real)                            :: xa_TL,xb_TL,dwb_TL,wb_TL
INTEGER                         :: na
!============================================================================
CALL lag_interp_weights_TL(x(1:n-1),x_TL(1:n-1),xt,aq,aq_TL,aw(1:n-1),aw_TL(1:n-1),&
             daw(1:n-1),daw_TL(1:n-1),n-1)
CALL lag_interp_weights_TL(x(2:n     ),x_TL(2:n     ),xt,bq,bq_TL,bw(2:n     ),bw_TL(2:n     ),&
             dbw(2:n     ),dbw_TL(2:n     ),n-1)
aw(n) =zero
daw(n)=zero
bw(1) =zero
dbw(1)=zero
!
aw_TL(n) =zero
daw_TL(n)=zero
bw_TL(1) =zero
dbw_TL(1)=zero
na=n/2
IF(na*2 /= n)STOP 'In lag_interp_smthWeights; n must be even'
xa   =x   (na)
xa_TL=x_TL(na)
xb   =x   (na+1)
xb_TL=x_TL(na+1)
dwb   = one          /(xb-xa)
dwb_TL=-(xb_TL-xa_TL)/(xb-xa)**2
wb   =             (xt-xa)*dwb
wb_TL=(-xa_TL)*dwb+(xt-xa)*dwb_TL
IF    (wb > one)THEN
   wb    =one
   dwb   =zero
   wb_TL =zero
   dwb_TL=zero
ELSEIF(wb < zero)THEN
   wb    =zero
   dwb   =zero
   wb_TL =zero
   dwb_TL=zero

ENDIF

bw    =bw    -aw
bw_TL =bw_TL -aw_TL
dbw   =dbw   -daw
dbw_TL=dbw_TL-daw_TL

!w=aw+wb*bw
dw   =daw   + wb   *dbw           + dwb   *bw
dw_TL=daw_TL+(wb_TL*dbw+wb*dbw_TL)+(dwb_TL*bw+dwb*bw_TL)
end subroutine lag_interp_smthWeights_TL


!============================================================================
SUBROUTINE lag_interp_smthWeights_AD(x,x_AD,xt,aq,aq_AD,bq,bq_AD,w_AD,dw,dw_AD,n)
!============================================================================
INTEGER            ,INTENT(IN   ) :: n
REAL(kind_real)               ,INTENT(IN   ) :: xt
REAL(kind_real)  ,INTENT(IN   ) :: x(n)
REAL(kind_real), INTENT(IN   ) :: aq(n-1),bq(n-1)
REAL(kind_real),INTENT(INOUT) :: aq_AD(n-1),bq_AD(n-1)
REAL(kind_real),INTENT(  OUT) :: dw(n)
REAL(kind_real),INTENT(INOUT) :: x_AD(n),dw_AD(n),w_AD(n)
!-----------------------------------------------------------------------------
REAL(kind_real)                 :: aw(n),bw(n),daw(n),dbw(n)
REAL(kind_real)                 :: aw_AD(n),bw_AD(n),daw_AD(n),dbw_AD(n)
REAL(kind_real)                              :: xa,xb,dwb,wb
REAL(kind_real)                              :: xa_AD,xb_AD,wb_AD,dwb_AD
INTEGER                           :: na
!============================================================================
daw_AD=zero;wb_AD=zero;dbw_AD=zero;dwb_AD=zero;bw_AD=zero
aw_AD =zero;xb_AD=zero;xa_AD =zero

! passive variables needed (from forward code)
CALL lag_interp_weights(x(1:n-1),xt,aq,aw(1:n-1),daw(1:n-1),n-1)
CALL lag_interp_weights(x(2:n  ),xt,bq,bw(2:n  ),dbw(2:n  ),n-1)

aw(n) =zero
daw(n)=zero
bw(1) =zero
dbw(1)=zero
na=n/2
IF(na*2 /= n)STOP 'In lag_interp_smthWeights; n must be even'
xa =x(na     )
xb =x(na+1)
dwb=one/(xb-xa)
wb =(xt-xa)*dwb
IF    (wb>one)THEN
   wb =one
   dwb=zero
ELSEIF(wb<zero)THEN
   wb =zero
   dwb=zero
ENDIF
bw =bw -aw
dbw=dbw-daw
!w=aw+wb*bw ! not needed
dw=daw+wb*dbw+dwb*bw ! not needed
!
!
daw_AD=daw_AD+dw_AD
wb_AD =wb_AD +dot_product(dbw,dw_AD)
dbw_AD=dbw_AD+wb*dw_AD
dwb_AD=dwb_AD+dot_product(bw,dw_AD)
bw_AD =bw_AD +dwb*dw_AD

aw_AD=aw_AD+w_AD
wb_AD=wb_AD+dot_product(bw,w_AD)
bw_AD=bw_AD+wb*w_AD

daw_AD=daw_AD-dbw_AD
aw_AD =aw_AD -bw_AD

IF(wb>one)THEN
   wb_AD =zero
   dwb_AD=zero
ELSEIF(wb<zero)THEN
   wb_AD =zero
   dwb_AD=zero
ENDIF

xa_AD        =xa_AD-wb_AD*dwb
dwb_AD       =dwb_AD+(xt-xa)*wb_AD
xb_AD        =xb_AD-(dwb_AD/(xb-xa)**2)
xa_AD        =xa_AD+(dwb_AD/(xb-xa)**2)
x_AD(na+1)=x_AD(na+1)+xb_AD
x_AD(na  )=x_AD(na  )+xa_AD

dbw_AD(1)=zero;bw_AD(1)=zero
daw_AD(n)=zero;aw_AD(n)=zero

CALL lag_interp_weights_AD(x(2:n     ),x_AD(2:n     ),xt,bq,bq_AD,bw_AD(2:n     ),&
             dbw_AD(2:n     ),n-1)

CALL lag_interp_weights_AD(x(1:n-1),x_AD(1:n-1),xt,aq,aq_AD,aw_AD(1:n-1),&
             daw_AD(1:n-1),n-1)

end subroutine lag_interp_smthWeights_AD
!============================================================================
end module lag_interp_mod
