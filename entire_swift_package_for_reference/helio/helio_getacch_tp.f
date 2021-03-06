c*************************************************************************
c                        HELIO_GETACCH_TP.F
c*************************************************************************
c This subroutine calculates the acceleration on the test particles
c in the HELIOCENTRIC frame. 
c             Input:
c                  nbod        ==>  number of massive bodies (int scalor)
c                  ntp         ==>  number of tp bodies (int scalor)
c                  mass        ==>  mass of bodies (real array)
c                  j2rp2,j4rp4 ==>  J2*radii_pl^2 and  J4*radii_pl^4
c                                     (real scalars)
c                  xh,yh,zh    ==>  massive part position in helio coord 
c                                     (real arrays)
c                  xht,yht,zht ==>  test part position in heliocentric coord 
c                                     (real arrays)
c                  istat       ==>  status of the test paricles
c                                      (integer array)
c                                      istat(i) = 0 ==> active:  = 1 not
c                                    NOTE: it is really a 2d array but 
c                                          we only use the 1st row
c             Output:
c               axht,ayht,azht ==>  tp acceleration in helio coord 
c                                   (real arrays)
c
c remarks: Mased on getaccel_tp
c Author:  Hal Levison  
c Date:    2/18/93
c Last revision: 11/8/13

      subroutine helio_getacch_tp(nbod,ntp,mass,j2rp2,j4rp4,
     &     xh,yh,zh,xht,yht,zht,istat,axht,ayht,azht)

      include '../swift.inc'

c...  Inputs: 
      integer nbod,ntp,istat(NTPMAX)
      real*8 mass(NPLMAX),xh(NPLMAX),yh(NPLMAX),zh(NPLMAX)
      real*8 xht(NTPMAX),yht(NTPMAX),zht(NTPMAX),j2rp2,j4rp4

c...  Outputs:
      real*8 axht(NTPMAX),ayht(NTPMAX),azht(NTPMAX)
                
c...  Internals:
      integer i
      real*8 ir3h(NPLMAX),irh(NPLMAX)
      real*8 ir3ht(NTPMAX),irht(NTPMAX)
      real*8 aoblx(NPLMAX),aobly(NPLMAX),aoblz(NPLMAX)
      real*8 aoblxt(NTPMAX),aoblyt(NTPMAX),aoblzt(NTPMAX)

c----
c...  Executable code 

c...  get thr r^-3's  for the planets and test paricles
      call getacch_ir3(nbod,2,xh,yh,zh,ir3h,irh)
      call getacch_ir3(ntp,1,xht,yht,zht,ir3ht,irht)

c...  now the third terms
      call getacch_ah3_tp(nbod,ntp,mass,xh,yh,zh,xht,yht,zht,
     &     istat,axht,ayht,azht)

c...  Now do j2 and j4 stuff
      if(j2rp2.ne.0.0d0) then
         call obl_acc(nbod,mass,j2rp2,j4rp4,xh,yh,zh,irh,
     &        aoblx,aobly,aoblz)
         call obl_acc_tp(ntp,istat,mass(1),j2rp2,j4rp4,xht,yht,zht,
     &        irht,aoblxt,aoblyt,aoblzt)
         do i = 1,ntp
            axht(i) = axht(i) + aoblxt(i)
            ayht(i) = ayht(i) + aoblyt(i)
            azht(i) = azht(i) + aoblzt(i)
         enddo
      endif

      return
      end      ! helio_getacch_tp

c---------------------------------------------------------------------




