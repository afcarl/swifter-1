!**********************************************************************************************************************************
!
!  Unit Name   : swifter_rmvs
!  Unit Type   : program
!  Project     : Swifter
!  Package     : main
!  Language    : Fortran 90/95
!
!  Description : Driver program for the Regularized Mixed Variable Symplectic algorithm
!
!  Input
!    Arguments : none
!    Terminal  : parameter file name
!    File      : none
!
!  Output
!    Arguments : none
!    Terminal  : error message
!                status messages
!    File      : none
!
!  Invocation  : % swifter_rmvs
!
!  Notes       : Reference: Levison, H. F. & Duncan, M. J. 1994. Icarus, 108, 18.
!
!                Adapted from Hal Levison and Martin Duncan's Swift program swift_rmvs3.f
!
!**********************************************************************************************************************************
PROGRAM swifter_rmvs

! Modules
     USE module_parameters
     USE module_swifter
     USE module_rmvs
     USE module_random_access
     USE module_interfaces
     IMPLICIT NONE

! Arguments
     LOGICAL(LGT)      :: lclose         ! Check for planet-test particle encounters
     LOGICAL(LGT)      :: lextra_force   ! Use user-supplied force routines
     LOGICAL(LGT)      :: lbig_discard   ! Dump planet data with discards
     LOGICAL(LGT)      :: lrhill_present ! Hill's sphere radius present
     INTEGER(I4B)      :: nplmax         ! Maximum number of planets
     INTEGER(I4B)      :: ntpmax         ! Maximum number of test particles
     INTEGER(I4B)      :: istep_out      ! Time steps between binary outputs
     INTEGER(I4B)      :: istep_dump     ! Time steps between dumps
     REAL(DP)          :: t0             ! Integration start time
     REAL(DP)          :: tstop          ! Integration stop time
     REAL(DP)          :: dt             ! Time step
     REAL(DP)          :: j2rp2          ! J2*R^2 term for central body
     REAL(DP)          :: j4rp4          ! J4*R^4 term for central body
     REAL(DP)          :: rmin           ! Minimum heliocentric radius for test particle
     REAL(DP)          :: rmax           ! Maximum heliocentric radius for test particle
     REAL(DP)          :: rmaxu          ! Maximum unbound heliocentric radius for test particle
     REAL(DP)          :: qmin           ! Minimum pericenter distance for test particle
     REAL(DP)          :: qmin_alo       ! Minimum semimajor axis for qmin
     REAL(DP)          :: qmin_ahi       ! Maximum semimajor axis for qmin
     CHARACTER(STRMAX) :: qmin_coord     ! Coordinate frame to use for qmin
     CHARACTER(STRMAX) :: encounter_file ! Name of output file for encounters
     CHARACTER(STRMAX) :: inplfile       ! Name of input file for planets
     CHARACTER(STRMAX) :: intpfile       ! Name of input file for test particles
     CHARACTER(STRMAX) :: in_type        ! Format of input data files
     CHARACTER(STRMAX) :: outfile        ! Name of output binary file
     CHARACTER(STRMAX) :: out_type       ! Binary format of output file
     CHARACTER(STRMAX) :: out_form       ! Data to write to output file
     CHARACTER(STRMAX) :: out_stat       ! Open status for output binary file

! Internals
     LOGICAL(LGT)                                     :: lfirst
     INTEGER(I4B)                                     :: npl, ntp, ntp0, nsp, iout, idump, iloop
     REAL(DP)                                         :: t, tfrac, tbase, eoffset
     CHARACTER(STRMAX)                                :: inparfile
     TYPE(swifter_pl), POINTER                        :: swifter_pl1P
     TYPE(swifter_tp), POINTER                        :: swifter_tp1P, swifter_tpd1P
     TYPE(rmvs_pl), DIMENSION(:), ALLOCATABLE, TARGET :: rmvs_plA
     TYPE(rmvs_tp), DIMENSION(:), ALLOCATABLE, TARGET :: rmvs_tpA
     TYPE(rmvs_pl), POINTER                           :: rmvs_pl1P
     TYPE(rmvs_tp), POINTER                           :: rmvs_tp1P, rmvs_tpd1P

! Executable code
     CALL util_version
     WRITE(*, 100, ADVANCE = "NO") "Enter name of parameter data file: "
     READ(*, 100) inparfile
 100 FORMAT(A)
     inparfile = TRIM(ADJUSTL(inparfile))
     CALL io_init_param(inparfile, nplmax, ntpmax, t0, tstop, dt, inplfile, intpfile, in_type, istep_out, outfile, out_type,      &
          out_form, out_stat, istep_dump, j2rp2, j4rp4, lclose, rmin, rmax, rmaxu, qmin, qmin_coord, qmin_alo, qmin_ahi,          &
          encounter_file, lextra_force, lbig_discard, lrhill_present)
     IF (.NOT. lrhill_present) THEN
          WRITE(*, *) "SWIFTER Error:"
          WRITE(*, *) "   Integrator RMVS requires planet Hill sphere radii on input"
          CALL util_exit(FAILURE)
     END IF
     CALL io_getn(inplfile, intpfile, in_type, npl, nplmax, ntp, ntpmax)
     ALLOCATE(rmvs_plA(nplmax))
     CALL set_point(rmvs_plA)
     IF (ntp > 0) THEN
          ALLOCATE(rmvs_tpA(ntpmax))
          CALL set_point(rmvs_tpA)
     END IF
     CALL rmvs_setup(npl, ntp, rmvs_plA, rmvs_tpA, rmvs_pl1P, rmvs_tp1P, swifter_pl1P, swifter_tp1P)
     CALL io_init_pl(inplfile, in_type, lclose, lrhill_present, npl, swifter_pl1P)
     CALL io_init_tp(intpfile, in_type, ntp, swifter_tp1P)
     CALL util_valid(npl, ntp, swifter_pl1P, swifter_tp1P)
     lfirst = .TRUE.
     ntp0 = ntp
     t = t0
     tbase = t0
     iloop = 0
     iout = istep_out
     idump = istep_dump
     nsp = 0
     eoffset = 0.0_DP
     NULLIFY(rmvs_tpd1P)
     IF (istep_out > 0) CALL io_write_frame(t, npl, ntp, swifter_pl1P, swifter_tp1P, outfile, out_type, out_form, out_stat)
     WRITE(*, *) " *************** MAIN LOOP *************** "
     DO WHILE ((t < tstop) .AND. ((ntp0 == 0) .OR. (ntp > 0)))
          CALL rmvs_step(lfirst, lextra_force, t, npl, nplmax, ntp, ntpmax, rmvs_pl1P, rmvs_tp1P, j2rp2, j4rp4, dt,               &
               encounter_file, out_type)
          iloop = iloop + 1
          IF (iloop == LOOPMAX) THEN
               tbase = tbase + iloop*dt
               iloop = 0
          END IF
          t = tbase + iloop*dt
          CALL rmvs_discard(t, npl, ntp, nsp, rmvs_pl1P, rmvs_tp1P, rmvs_tpd1P, dt, rmin, rmax, rmaxu, qmin, qmin_coord,          &
               qmin_alo, qmin_ahi, lclose, lrhill_present)
          IF (nsp > 0) THEN
               swifter_tp1P => rmvs_tp1P%whm%swifter
               swifter_tpd1P => rmvs_tpd1P%whm%swifter
               CALL io_discard_write(t, npl, nsp, swifter_pl1P, swifter_tpd1P, DISCARD_FILE, lbig_discard)
               nsp = 0
               NULLIFY(rmvs_tpd1P)
          END IF
          IF (istep_out > 0) THEN
               iout = iout - 1
               IF (iout == 0) THEN
                    CALL io_write_frame(t, npl, ntp, swifter_pl1P, swifter_tp1P, outfile, out_type, out_form, out_stat)
                    iout = istep_out
               END IF
          END IF
          IF (istep_dump > 0) THEN
               idump = idump - 1
               IF (idump == 0) THEN
                    tfrac = (t - t0)/(tstop - t0)
                    WRITE(*, 200) t, tfrac, npl, ntp
 200                FORMAT(" Time = ", ES12.5, "; fraction done = ", F5.3, "; Number of active pl, tp = ", I5, ", ", I5)
                    CALL io_dump_param(nplmax, ntpmax, ntp, t, tstop, dt, in_type, istep_out, outfile, out_type, out_form,        &
                         istep_dump, j2rp2, j4rp4, lclose, rmin, rmax, rmaxu, qmin, qmin_coord, qmin_alo, qmin_ahi,               &
                         encounter_file, lextra_force, lbig_discard, lrhill_present)
                    CALL io_dump_pl(npl, swifter_pl1P, lclose, lrhill_present)
                    IF (ntp > 0) CALL io_dump_tp(ntp, swifter_tp1P)
                    idump = istep_dump
               END IF
          END IF
     END DO
     CALL io_dump_param(nplmax, ntpmax, ntp, t, tstop, dt, in_type, istep_out, outfile, out_type, out_form, istep_dump, j2rp2,    &
          j4rp4, lclose, rmin, rmax, rmaxu, qmin, qmin_coord, qmin_alo, qmin_ahi, encounter_file, lextra_force, lbig_discard,     &
          lrhill_present)
     CALL io_dump_pl(npl, swifter_pl1P, lclose, lrhill_present)
     IF (ntp > 0) CALL io_dump_tp(ntp, swifter_tp1P)
     IF (ALLOCATED(rmvs_plA)) DEALLOCATE(rmvs_plA)
     IF (ALLOCATED(rmvs_tpA)) DEALLOCATE(rmvs_tpA)
     CALL util_exit(SUCCESS)

     STOP

END PROGRAM swifter_rmvs
!**********************************************************************************************************************************
!
!  Author(s)   : David E. Kaufmann
!
!  Revision Control System (RCS) Information
!
!  Source File : $RCSfile$
!  Full Path   : $Source$
!  Revision    : $Revision$
!  Date        : $Date$
!  Programmer  : $Author$
!  Locked By   : $Locker$
!  State       : $State$
!
!  Modification History:
!
!  $Log$
!**********************************************************************************************************************************
