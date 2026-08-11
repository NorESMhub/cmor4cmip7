module m_modelsocn

  use netcdf
  use cmor_users_functions
  use m_utilities
  use m_namelists
  use m_jsons

  implicit none

  ! Netcdf variables
  integer, save         :: ii, jj, kk, ncid, rhid, dimid, status

  ! Grid dimensions and variables
  real(r8), save                                :: voglb, aoglb
  real(r8), save                                :: rhoglb0=0., rhoglb=0.
  integer, save                                 :: idm, jdm, kdm = 0, ddm = 0, ldm = 0, rdm = 0, sdm = 0, slenmax2
  integer, parameter                            :: ncrns = 4
  integer, allocatable, save, dimension(:, :)   :: basin
  real(r8), allocatable, save, dimension(:)     :: xvec, yvec, kvec, kvechalf, &
                                                   sigma, sigmahalf, depth, slat
  real(r8), allocatable, save, dimension(:, :)  :: parea, pmask, pdepth, plon, &
                                                   plat, ulon, ulat, vlon, vlat, slat_bnds, sigma_bnds, sigmahalf_bnds, &
                                                   depth_bnds, uscaley, vscalex, udepth, vdepth
  real(r8), allocatable, save, dimension(:, :, :)   :: plon_crns, plat_crns, &
                                                       ulon_crns, ulat_crns, vlon_crns, vlat_crns, plon_crnsp, plat_crnsp, &
                                                       ulon_crnsp, ulat_crnsp, vlon_crnsp, vlat_crnsp
  real(r4), allocatable, save, dimension(:, :)      :: bpini
  real(r4), allocatable, save, dimension(:, :, :)   :: dpini, sini, tini
  character(len=slenmax), allocatable, save, dimension(:)   :: region1, section1
  character, allocatable, save, dimension(:, :)             :: region, section
  character(len=slenmax), save                              :: tcoord, zcoord, s1
  character(len=slenmax), save                              :: grid, grid_label

  ! Gravity
  real(r8), parameter :: g = 9.80665, ginv = 1.0/g, sref = 35.0

  ! Dataset related variables
  character(len=slenmax), save          :: ivnm, ovnm, vunits, vpositive, vtype
  character(len=slenmax), save          :: bvnm, cvnm, original_name
  character(len=slenmax*10), save       :: vcomment, vhistory
  logical, save :: lsumz
  logical       :: found

  ! Table related variables
  character(len=slenmax), save          :: table, tablepath

  ! Cmor parameters
  character(len=1024)   :: fnmo
  integer, save         :: iaxid, jaxid, kaxid, laxid, raxid, saxid, taxid, &
                           grdid, varid, table_id, table_id_grid, error_flag

  ! String for module special
  character(len=slenmax), save          :: special

  ! Data fields
  real(r4), allocatable, save, dimension(:, :, :)   :: fld, fld2, fldtmp, fldacc, dp
  real(r4), allocatable, save, dimension(:, :)      :: sealv, pbot
  real(r8)                                          :: sfac, offs, fill

  ! Auxillary variables for special operations
  character(len=slenmax), save                          :: str1, str2, dims

  character(len=slenmax), allocatable, save, dimension(:)     :: sources, dimensions
  integer, allocatable, save, dimension(:)                    :: idx
  real(r8), allocatable, save, dimension(:)                   :: factors

contains

  ! -----------------------------------------------------------------

  subroutine ocn2cmor

    implicit none

    logical :: badrec, last, first
    integer :: k, m, n
    integer :: romon = 365*10*2
    character(len=slenmax), dimension(5) :: itags

    badrec = .false.

    ! Print start information
    if (verbose) then
      write (*, *)
      write (*, *) '----------------------------'
      write (*, *) '--- Process ocean output ---'
      write (*, *) '----------------------------'
      write (*, *)
    end if

    itags = [tagoyr, tagoyrbgc, tagomon, tagomonbgc, tagoday]

    do n = 1, size(itags)
      itag = itags(n)
      write(*,*) 'itag:',trim(itag)
      call scan_files(reset=.true.)

      if (len_trim(fnm) == 0) then
        if (verbose) write (*, *) &
          'WARNING: no file found for case dir|tag|year1|month1|yearn|monthn: ', &
          trim(ibasedir)//'/'//trim(casename), '|', trim(itag), '|', &
          year1, '|', month1, '|', yearn, '|', monthn
        !cycle
      end if
    end do

    !write(*, *) 'Read grid information from input files'
    itag=tagomon    ! ensure read grid info from monthly output
    call scan_files(reset=.true.)
    call read_gridinfo_ifile

!   ! Process table Omon
!   write(*, *) 'Process table Omon'
    pomon = ''
    fnm = pomon

    ! filter only ocean variables, facilitate parallisation
    n = count(realms == 'ocean' .or. realms == 'ocnBgchem')
    allocate (idx(n))
    k = 1
    do n = 1, n_datasets
      if (realms(n) == 'ocean' .or. realms(n) == 'ocnBgchem') then
        idx(k) = n
        k = k + 1
      end if
    end do

    main_loop: do n = 1, size(idx)

      if (skip_dataset(n, n_datasets)) cycle

      realm = trim(realms(idx(n)))

!     ! Map namelist variables
      bvnm = trim(branded_names(idx(n)))
      cvnm = trim(compound_names(idx(n)))
      frequency = trim(frequencies(idx(n)))
      region_label = trim(regions(idx(n)))
      ovnm = bvnm
      table = 'CMIP7_'//trim(realm)//'.json'

      write (*, *) 'cvnm:', trim(cvnm)

      ! Initialize variable attributes
      vpositive = ''
      vcomment = ''
      vhistory = ''
      special = ''
      tcoord = ''
      zcoord = ''

      ! Select file tag according to realm and frequency
      call select_ocn_ftag(realm, frequency, itag)
      if (bvnm == 'sf6_tavg-ol-hxy-sea') call select_ocn_ftag('ocnBgchem', frequency, itag)

      ! Get variable attributes from table and mapfile
      call json_get_units(trim(tabledir)//trim(table), trim(ovnm), vunits)
      call json_get_vertcoord(trim(tabledir)//trim(table), trim(bvnm), zcoord, lfound=found)

      ! Get sources and factors from mapfile
      if (allocated(sources)) deallocate(sources)
      if (allocated(factors)) deallocate(factors)
      call json_get_original_name(trim(mapfile), trim(cvnm), original_name)
      call json_get_sources(trim(mapfile), trim(cvnm), sources, lfound=found)
      if (found) then
        allocate(factors(size(sources)))
        do k = 1, size(sources)
          call json_get_factor(trim(mapfile), trim(cvnm), sources(k), factors(k), lfound=found)
        end do
      else
        allocate(sources(1))
        allocate(factors(1))
        sources(1) = trim(original_name)
        factors(1) = 1.0
      end if
      ivnm = sources(1)

      call json_get_array_string(trim(tabledir)//trim(table), 'variable_entry.'//trim(bvnm)// &
                                 '.dimensions', dimensions, lfound=found)

      dims = dimensions(1)
      do k = 2, size(dimensions)
        write (*, *) 'dimension(k):', trim(dimensions(k))
        dims = trim(dims)//","//trim(dimensions(k))
      end do
      if (verbose) write (*, *) 'dims:', trim(dims)

      call special_cat
      if (verbose) then
        write (*, *) 'special:'
        write (*, *) trim(special)
      end if

!     ! Prepare output file
      call special_pre

      ! time independpent
      if (frequency == 'fx') then

        if (verbose) write (*, *) 'ovnm: ', trim(ovnm)
        IF (ovnm .EQ. 'basin_ti-u-hxy-u') THEN
          fnm = TRIM(griddata)//TRIM(ocnregnfile)
        else
          fnm = TRIM(griddata)//TRIM(ocngridfile)
        end if

        do k = 1, size(sources)
          if (.not. var_in_file(fnm, sources(k))) cycle main_loop
        end do
!       ivnm = sources(1)

        CALL open_ofile(ivnm, ovnm, fx=.TRUE.)

! --- - Read field
        CALL read_field
!
! --- - Post Processing
        CALL special_post
!
! --- - Write field
        CALL write_field
! --- - Close output file
        CALL close_ofile

      ! time dependpent
      else

        call scan_files(reset=.true.)

        if (len_trim(fnm) == 0) then
          if (verbose) write (*, *) &
            'WARNING: no file found for case dir|tag|year1|month1|yearn|monthn: ', &
            trim(ibasedir)//'/'//trim(casename), '|', trim(itag), '|', &
            year1, '|', month1, '|', yearn, '|', monthn
          !cycle
        end if

        ! check if variable(s) in file
        do k = 1, size(sources)
          if (.not. var_in_file(fnm, sources(k))) cycle main_loop
        end do

!       ! Loop over input files
        m = 0
        do
          m = m + 1

!         ! Open output file
          if (mod(m - 1, romon) == 0) then
            call open_ofile(ivnm, ovnm)
          end if

!         ! Read variable into buffer (average if necessary)
          rec = 0
          call scan_files(reset=.false.)
          if (rec == 0) exit
          call read_tslice(rec, badrec, fnm)

          !! calcluate tval and tbnds
          select case (frequency)
          case ('mon')
            tbnds(:, 1) = mbnd
            tval = 0.5*(tbnds(1, 1) + tbnds(2, 1))
          case ('day')
            tbnds(1, 1) = tval(1) - 0.5
            tbnds(2, 1) = tval(1) + 0.5
          case ('yr')
            tbnds(1, 1) = tval(1) - 365./2.
            tbnds(2, 1) = tval(1) + 365./2.
          end select

          ! Post processing
          call special_post

!         ! Write time slice to output file
          call write_tslice

!         ! Close output file if max rec has been reached
          if (mod(m, romon) == 0) call close_ofile

        end do

!       ! Close output file if still open
        if (mod(m, romon) > 0) call close_ofile

      end if

      if (allocated(sources)) deallocate (sources)
      if (allocated(factors)) deallocate (factors)

    end do main_loop

    if (allocated(sigma)) deallocate (sigma)
    if (allocated(sigmahalf)) deallocate (sigmahalf)
    if (allocated(sigma_bnds)) deallocate (sigma_bnds)
    if (allocated(sigmahalf_bnds)) deallocate (sigmahalf_bnds)

    if (allocated(depth)) deallocate (depth)
    if (allocated(depth_bnds)) deallocate (depth_bnds)

    if (allocated(slat)) deallocate (slat)
    if (allocated(slat_bnds)) deallocate (slat_bnds)

    if (allocated(section)) deallocate (section)
    if (allocated(section1)) deallocate (section1)

    if (allocated(region)) deallocate (region)
    if (allocated(region1)) deallocate (region1)

    deallocate (parea, pmask, pdepth, &
                plon, plat, bpini, &
                ulon, ulat, vlon, vlat, &
                plon_crns, plat_crns, &
                ulon_crns, ulat_crns, &
                vlon_crns, vlat_crns, &
                plon_crnsp, plat_crnsp, &
                ulon_crnsp, ulat_crnsp, &
                vlon_crnsp, vlat_crnsp, &
                sealv, xvec, yvec, kvec, pbot, &
                dpini, sini, tini, &
                kvechalf, uscaley, vscalex, &
                udepth, vdepth, basin, stat=status)

    if (allocated(idx)) deallocate (idx)

  end subroutine ocn2cmor

  ! -----------------------------------------------------------------
  subroutine special_cat

    implicit none

    integer :: n

    character(len=slenmax), dimension(:), allocatable  :: keys
    character(len=slenmax)        :: key, val

    call json_get_preproc_keys(trim(mapfile), &
                               trim(cvnm), keys, lfound=found)
    if (found) then
      do n = 1, size(keys)
        key = keys(n)
        call json_get_preproc_val(trim(mapfile), &
                                  trim(cvnm), trim(key), val, lfound=found)
        if (found .and. val /= 'false') then
          special = trim(special)//trim(key)//";"
        else
          cycle
        end if
      end do
    end if
    if (allocated(keys)) deallocate (keys)

    call json_get_postproc_keys(trim(mapfile), &
                                trim(cvnm), keys, lfound=found)
    if (found) then
      do n = 1, size(keys)
        key = keys(n)
        call json_get_postproc_val(trim(mapfile), &
                                   trim(cvnm), trim(key), val, lfound=found)
        if (found .and. val /= 'false') then
          write (*, *) trim(key), ":", trim(val)
          special = trim(special)//trim(key)//";"
        else
          cycle
        end if
      end do
    end if
    if (allocated(keys)) deallocate (keys)

  end subroutine special_cat

  ! -----------------------------------------------------------------
  subroutine special_pre

    implicit none

    integer :: i, j, k, n

    character(len=slenmax), dimension(:), allocatable  :: keys
    character(len=slenmax)        :: key, val

    ! get variable history
    call json_get_history(trim(mapfile), trim(cvnm), val, lfound=found)
    if (found) vhistory = val

    lsumz = .false.
    call json_get_preproc_keys(trim(mapfile), &
                               trim(cvnm), keys, lfound=found)

    if (.not. found) return

    do n = 1, size(keys)
      key = keys(n)
      call json_get_preproc_val(trim(mapfile), &
                                trim(cvnm), trim(key), val, lfound=found)
      if (.not. found) cycle
      if (verbose) write (*, *) trim(key), ":", trim(val)

      select case (key)

        ! Set positive attribute
      case ('positive')
        vpositive = trim(val)

        ! Compute vertical sum
!     case ('sumz')
!       lsumz = .true.

      case default
        write (*, *) 'ERROR: unknown pre-processing key: ', trim(key)

      end select
      !if (str1 == str2) exit
    end do

    if (allocated(keys)) deallocate (keys)

  end subroutine special_pre

  ! -----------------------------------------------------------------

  subroutine special_post

    implicit none

    integer     :: i, j, k, n
    real(r8)    :: r, rd, p, ptoptmp, pbottmp
    real(r8)    :: dptmp, ptmp

    character(len=slenmax), dimension(:), allocatable  :: keys
    character(len=slenmax) :: key, val

    call json_get_postproc_keys(trim(mapfile), &
                                trim(cvnm), keys, lfound=found)
    if (.not. found) return

    do n = 1, size(keys)
      key = keys(n)
      call json_get_postproc_val(trim(mapfile), &
                                 trim(cvnm), trim(key), val, lfound=found)

      if (.not. found .or. val=='false')  cycle

      select case (key)

        ! Compute depth below geoid from dz or pddpo
      case ('dz2zfull')
        fldacc(:, :, 1) = fld(:, :, 1)*0.5 - sealv
        do k = 2, kdm
          fldacc(:, :, k) = fldacc(:, :, k - 1) + (fld(:, :, k - 1) + fld(:, :, k))*0.5
        end do
        fld = fldacc

        ! Compute depth below geoid at interfaces from dz
      case ('dz2zhalf')
        fldacc(:, :, 1) = -sealv
        do k = 2, kdm
          fldacc(:, :, k) = fldacc(:, :, k - 1) + fld(:, :, k - 1)
        end do
        fld = fldacc

        ! Set ice free points to missing value
      case ('zero2missing')
        do k = 1, kk
          do j = 1, jj
            do i = 1, ii
              if (abs(fld(i, j, k)) < 1e-6) fld(i, j, k) = 1e20
            end do
          end do
        end do

        ! Compute vertical sum
      case ('sumz')
        do k = 2, kk
          do j = 1, jj
            do i = 1, ii
              if (abs(fld(i, j, k)) < 1e20) &
                fld(i, j, 1) = fld(i, j, 1) + fld(i, j, k)
            end do
          end do
        end do

        ! Compute vertical average
!     case ('avez')
!       if (val == 'false') cycle
!       do j = 1, jj
!         do i = 1, ii
!           if (abs(fld(i, j, 1)) < 1e20) &
!             fld(i, j, 1) = fld(i, j, 1) * dp(i, j, 1)
!           do k = 2, kk
!             if (abs(fld(i, j, k)) < 1e20) then
!               fld(i, j, 1) = fld(i, j, 1) + fld(i, j, k) * dp(i, j, k)
!               dp(i, j, 1) = dp(i, j, 1) + dp(i, j, k)
!             end if
!           end do
!         end do
!       end do
!       fld(i, j, 1) = fld(i, j, 1)/dp(i, j, 1)

        ! Devide by gravity constant
      case ('divide.g')
        do k = 1, kk
          do j = 1, jj
            do i = 1, ii
              if (fld(i, j, k) < 1e20) fld(i, j, k) = fld(i, j, k)/9.806
            end do
          end do
        end do

        ! Compute global 2d average
      case ('glbave2d')
        fld(1, 1, 1) = sum(fld(:, :, 1)*parea)/sum(parea)

        ! Compute thermo-steric sea level following Griffies et al., GMD 2016, H27
      case ('t2zostoga')
        rhoglb = 0.
        dp = dp*1.e-4     ! pa->dbar
        do j = 1, jdm
          do i = 1, idm
            if (pmask(i,j) == 0) cycle
            dptmp = 0.
            do k = 1, kdm
              if (fld(i,j,k)>=1.e20) cycle
              dptmp  = dptmp+0.5*dp(i,j,k)  ! mid-level pressure
              rhoglb = rhoglb + dp(i,j,k)*rho(dptmp, dble(fld(i,j,k)), sref)
              ptmp = ptmp + dp(i,j,k)
            end do
          end do
        end do
        rhoglb = rhoglb/ptmp

        fld(1, 1, 1) = voglb/aoglb*(1-rhoglb/rhoglb0)

        ! Compute fixed cell volume of interpolated grid
      case ('volcello')
        do j = 1, jj
          do i = 1, ii
            do k = ddm, 1, -1
              ptoptmp = min(depth_bnds(1, k), fld(i, j, 1))
              pbottmp = min(depth_bnds(2, k), fld(i, j, 1))
              fld(i, j, k) = (pbottmp - ptoptmp)*parea(i, j)
            end do
          end do
        end do

        ! Compute vertical velocity form vertical mass flux
      case ('wflx2wo')
        if (val == 'false') cycle
        do j = 1, jj
          do i = 1, ii
            do k = 1, kk
              if (fld(i, j, k) /= 1e20) then
                fld(i, j, k) = fld(i, j, k)/(1035.*parea(i, j))
              end if
            end do
          end do
        end do

        ! Compute fixed cell thickness
      case ('thkcello')
        do j = 1, jj
          do i = 1, ii
            do k = ddm, 1, -1
              fld(i, j, k) = min(fld(i, j, 1), depth_bnds(2, k)) - &
                             min(fld(i, j, 1), depth_bnds(1, k))
            end do
          end do
        end do

        ! Extract surface value from field on depth levels
          ! if output field is 2D while the input is 3D,
          ! the output will use the first level (k) of the input field by default
!     case ('lvl2srf') 
!       do j = 1, jj
!         do i = 1, ii
!           fld(i, j, 1) = fld(i, j, 1)
!         end do
!       end do

        ! Average with respect to pressure
      case ('dp.avg')
        do j = 1, jj
          do i = 1, ii
            if (fld(i, j, 1) /= 1e20) &
              fld(i, j, 1) = fld(i, j, 1)*fld2(i, j, 1)
            do k = 2, kk
              if (fld(i, j, k) /= 1e20) then
                fld(i, j, 1) = fld(i, j, 1) + fld(i, j, k)*fld2(i, j, k)
                fld2(i, j, 1) = fld2(i, j, 1) + fld2(i, j, k)
              end if
            end do
            if (fld(i, j, 1) /= 1e20) &
              fld(i, j, 1) = fld(i, j, 1)/fld2(i, j, 1)
          end do
        end do

        ! Average over upper 300 m
      case ('dzavg300m')
        fldtmp = 1.e20
        do j = 1, jj
          do i = 1, ii
            if (fld(i, j, 1) /= 1e20) then
              fldtmp(i, j, 1) = (min(300., pdepth(i, j), depth_bnds(2, 1)) &
                                 - min(300., pdepth(i, j), depth_bnds(1, 1)))
              fld(i, j, 1) = fld(i, j, 1)*fldtmp(i, j, 1)
            end if
            do k = 2, kk
              if (fld(i, j, k) /= 1e20) then
                fldtmp(i, j, k) = (min(300., pdepth(i, j), depth_bnds(2, k)) &
                                   - min(300., pdepth(i, j), depth_bnds(1, k)))
                fld(i, j, 1) = fld(i, j, 1) + fld(i, j, k)*fldtmp(i, j, k)
                fldtmp(i, j, 1) = fldtmp(i, j, 1) + fldtmp(i, j, k)
              end if
            end do
            if (fld(i, j, 1) /= 1e20) &
              fld(i, j, 1) = fld(i, j, 1)/fldtmp(i, j, 1)
          end do
        end do

        ! Average over upper 700 m
      case ('dzavg700m')
        fldtmp = 1.e20
        do j = 1, jj
          do i = 1, ii
            if (fld(i, j, 1) /= 1e20) then
              fldtmp(i, j, 1) = (min(700., pdepth(i, j), depth_bnds(2, 1)) &
                                 - min(700., pdepth(i, j), depth_bnds(1, 1)))
              fld(i, j, 1) = fld(i, j, 1)*fldtmp(i, j, 1)
            end if
            do k = 2, kk
              if (fld(i, j, k) /= 1e20) then
                fldtmp(i, j, k) = (min(700., pdepth(i, j), depth_bnds(2, k)) &
                                   - min(700., pdepth(i, j), depth_bnds(1, k)))
                fld(i, j, 1) = fld(i, j, 1) + fld(i, j, k)*fldtmp(i, j, k)
                fldtmp(i, j, 1) = fldtmp(i, j, 1) + fldtmp(i, j, k)
              end if
            end do
            if (fld(i, j, 1) /= 1e20) &
              fld(i, j, 1) = fld(i, j, 1)/fldtmp(i, j, 1)
          end do
        end do

        ! Average over upper 2000 m
      case ('dzavg2000m')
        fldtmp = 1.e20
        do j = 1, jj
          do i = 1, ii
            if (fld(i, j, 1) /= 1e20) then
              fldtmp(i, j, 1) = (min(2000., pdepth(i, j), depth_bnds(2, 1)) &
                                 - min(2000., pdepth(i, j), depth_bnds(1, 1)))
              fld(i, j, 1) = fld(i, j, 1)*fldtmp(i, j, 1)
            end if
            do k = 2, kk
              if (fld(i, j, k) /= 1e20) then
                fldtmp(i, j, k) = (min(2000., pdepth(i, j), depth_bnds(2, k)) &
                                   - min(2000., pdepth(i, j), depth_bnds(1, k)))
                fld(i, j, 1) = fld(i, j, 1) + fld(i, j, k)*fldtmp(i, j, k)
                fldtmp(i, j, 1) = fldtmp(i, j, 1) + fldtmp(i, j, k)
              end if
            end do
            if (fld(i, j, 1) /= 1e20) &
              fld(i, j, 1) = fld(i, j, 1)/fldtmp(i, j, 1)
          end do
        end do

      case ('pbot2dp')
        !fldtmp = 1e20
        do j = 1, jj
          do i = 1, ii
            if (pbot(i, j) /= 1e20) then
              do k = 1, kk
                fld(i, j, k) = (min(depth_bnds(2, k), pdepth(i, j)) - min(depth_bnds(1, k), pdepth(i, j))) &
                               /pdepth(i, j)*pbot(i, j)
              end do
            end if
          end do
        end do

        ! uatm to Pa
      case ('muatm2Pa')
        do k = 1, kk
          do j = 1, jj
            do i = 1, ii
              if (fld(i, j, k) /= 1e20) fld(i, j, k) = fld(i, j, k)*0.101325
            end do
          end do
        end do

        ! percent
      case ('percent')
        do k = 1, kk
          do j = 1, jj
            do i = 1, ii
              if (fld(i, j, k) /= 1e20) fld(i, j, k) = fld(i, j, k)*100.
            end do
          end do
        end do
      
      case default
        write (*, *) 'ERROR: unknown post-processing key: ', trim(key)

      end select

      !if (str1 == str2) exit
    end do

    if (allocated(keys)) deallocate (keys)

  end subroutine special_post

  ! -----------------------------------------------------------------

  subroutine read_gridinfo_ifile

    implicit none

    logical         :: check
    integer         :: i, j, k, n, fid
    real(r8)        :: missing
    real(r8)        :: phiu, phil
    real(r8)        :: dptmp, ptmp

    ! Open first input file
    call scan_files(reset=.true.)
    !write(*,*) 'fnm:',trim(fnm)
    write(*,*) 'read grid information'

    status = nf90_open(fnm, nf90_nowrite, ncid)
    call handle_ncerror(status)

    ! Read dimensions
    status = nf90_inq_dimid(ncid, 'x', dimid)
    call handle_ncerror(status)
    status = nf90_inquire_dimension(ncid, dimid, len=idm)
    call handle_ncerror(status)

    status = nf90_inq_dimid(ncid, 'y', dimid)
    call handle_ncerror(status)
    status = nf90_inquire_dimension(ncid, dimid, len=jdm)
    call handle_ncerror(status)

    status = nf90_inq_dimid(ncid, 'layer', dimid)
    if (status == nf90_noerr) then
      status = nf90_inquire_dimension(ncid, dimid, len=kdm)
      call handle_ncerror(status)
      allocate (sigma(kdm), sigmahalf(kdm + 1), sigma_bnds(2, kdm), &
                sigmahalf_bnds(2, kdm + 1), stat=status)
      if (status /= 0) stop 'cannot ALLOCATE enough memory (1b)'
      status = nf90_inq_varid(ncid, 'sigma', rhid)
      call handle_ncerror(status)
      status = nf90_get_var(ncid, rhid, sigma)
      call handle_ncerror(status)
      sigma_bnds(1, 1) = sigma(1) - 0.5*(sigma(2) - sigma(1))
      sigma_bnds(2, 1) = 0.5*(sigma(2) + sigma(1))
      do k = 2, kdm - 1
        sigma_bnds(1, k) = 0.5*(sigma(k) + sigma(k - 1))
        sigma_bnds(2, k) = 0.5*(sigma(k) + sigma(k + 1))
      end do
      sigma_bnds(1, kdm) = 0.5*(sigma(kdm) + sigma(kdm - 1))
      sigma_bnds(2, kdm) = sigma(kdm) + 0.5*(sigma(kdm) - sigma(kdm - 1))
      sigmahalf(1:kdm) = sigma_bnds(1, 1:kdm)
      sigmahalf(kdm + 1) = sigma_bnds(2, kdm)
      sigmahalf_bnds(1, 2:kdm + 1) = sigma
      sigmahalf_bnds(2, 1:kdm) = sigma
      sigmahalf_bnds(1, 1) = sigmahalf(1)
      sigmahalf_bnds(2, kdm + 1) = sigmahalf(kdm + 1)
    end if

    status = nf90_inq_dimid(ncid, 'depth', dimid)
    if (status == nf90_noerr) then
      status = nf90_inquire_dimension(ncid, dimid, len=ddm)
      call handle_ncerror(status)
      allocate (depth(ddm), depth_bnds(2, ddm), stat=status)
      if (status /= 0) stop 'cannot ALLOCATE enough memory (1c)'
      status = nf90_inq_varid(ncid, 'depth', rhid)
      call handle_ncerror(status)
      status = nf90_get_var(ncid, rhid, depth)
      call handle_ncerror(status)
      status = nf90_inq_varid(ncid, 'depth_bnds', rhid)
      call handle_ncerror(status)
      status = nf90_get_var(ncid, rhid, depth_bnds)
      call handle_ncerror(status)
    end if

    !write(*, *) 'read lat'
    status = nf90_inq_dimid(ncid, 'lat', dimid)
    if (status == nf90_noerr) then
      status = nf90_inquire_dimension(ncid, dimid, len=ldm)
      call handle_ncerror(status)
      allocate (slat(ldm), slat_bnds(2, ldm), stat=status)
      if (status /= 0) stop 'cannot ALLOCATE enough memory (1c)'
      status = nf90_inq_varid(ncid, 'lat', rhid)
      call handle_ncerror(status)
      status = nf90_get_var(ncid, rhid, slat)
      call handle_ncerror(status)
      slat_bnds(1, 1) = max(-90., slat(1) - 0.5*(slat(2) - slat(1)))
      slat_bnds(2, 1) = 0.5*(slat(2) + slat(1))
      do j = 2, ldm - 1
        slat_bnds(1, j) = 0.5*(slat(j) + slat(j - 1))
        slat_bnds(2, j) = 0.5*(slat(j) + slat(j + 1))
      end do
      slat_bnds(1, ldm) = 0.5*(slat(ldm) + slat(ldm - 1))
      slat_bnds(2, ldm) = min(90., slat(ldm) + 0.5*(slat(ldm) - slat(ldm - 1)))
    end if

    !write(*, *) 'read region'
    status = nf90_inq_varid(ncid, 'region', rhid)
    if (status == nf90_noerr) then
      status = nf90_inq_dimid(ncid, 'region', dimid)
      call handle_ncerror(status)
      status = nf90_inquire_dimension(ncid, dimid, len=rdm)
      call handle_ncerror(status)
      status = nf90_inq_dimid(ncid, 'slenmax', dimid)
      status = nf90_inquire_dimension(ncid, dimid, len=slenmax2)
      call handle_ncerror(status)
      allocate (region(slenmax2, rdm), region1(rdm), stat=status)
      if (status /= 0) stop 'cannot ALLOCATE enough memory (1d)'
      status = nf90_inq_varid(ncid, 'region', rhid)
      call handle_ncerror(status)
      !write(*, *) 'read region', slenmax2, rdm, shape(region)
      status = nf90_get_var(ncid, rhid, region, (/1, 1/), (/slenmax2, rdm/))
      call handle_ncerror(status)
      region1 = ' '
      do i = 1, rdm
        do j = 1, slenmax2
          region1(i) (j:j) = region(j, i)
        end do
      end do
    end if

!   write (*, *) 'read section'
    status = nf90_inq_varid(ncid, 'section', rhid)
    if (status == nf90_noerr) then
      status = nf90_inq_dimid(ncid, 'section', dimid)
      call handle_ncerror(status)
      status = nf90_inquire_dimension(ncid, dimid, len=sdm)
      call handle_ncerror(status)
      status = nf90_inq_dimid(ncid, 'slenmax', dimid)
      status = nf90_inquire_dimension(ncid, dimid, len=slenmax2)
      call handle_ncerror(status)
      allocate (section(slenmax2, sdm), section1(sdm), stat=status)
      if (status /= 0) stop 'cannot ALLOCATE enough memory (1d)'
      status = nf90_inq_varid(ncid, 'section', rhid)
      call handle_ncerror(status)
      !write(*, *) 'sdm,slenmax2:', sdm, slenmax2
      status = nf90_get_var(ncid, rhid, section, (/1, 1/), (/slenmax2, sdm/))
      call handle_ncerror(status)
      !write(*, *) 'section:', section
      section1 = ' '
      do i = 1, sdm
        s1 = ' '
        do j = 1, slenmax2
          s1(j:j) = section(j, i)
        end do
        if (trim(s1) == 'taiwan_and_luzon_straits') then
          section1(i) = 'taiwan_luzon_straits'
        else
          section1(i) = trim(s1)
        end if
      end do
    end if

    ! Read calendar information (change reference year)
    status = nf90_inq_varid(ncid, 'time', rhid)
    call handle_ncerror(status)
    status = nf90_get_att(ncid, rhid, 'calendar', calendar)
    call handle_ncerror(status)
    status = nf90_get_att(ncid, rhid, 'units', calunits)
    call handle_ncerror(status)
    read (calunits(12:15), '(i4.4)') exprefyear

    ! Close first file
    status = nf90_close(ncid)
    call handle_ncerror(status)

    ! Read longitudes, latitudes
    allocate (parea(idm, jdm), pmask(idm, jdm), pdepth(idm, jdm), &
              plon(idm, jdm), plat(idm, jdm), bpini(idm, jdm), &
              ulon(idm, jdm), ulat(idm, jdm), vlon(idm, jdm), vlat(idm, jdm), &
              plon_crns(idm, jdm, ncrns), plat_crns(idm, jdm, ncrns), &
              ulon_crns(idm, jdm, ncrns), ulat_crns(idm, jdm, ncrns), &
              vlon_crns(idm, jdm, ncrns), vlat_crns(idm, jdm, ncrns), &
              plon_crnsp(ncrns, idm, jdm), plat_crnsp(ncrns, idm, jdm), &
              ulon_crnsp(ncrns, idm, jdm), ulat_crnsp(ncrns, idm, jdm), &
              vlon_crnsp(ncrns, idm, jdm), vlat_crnsp(ncrns, idm, jdm), &
              sealv(idm, jdm), xvec(idm), yvec(jdm), kvec(kdm), pbot(idm, jdm), &
              dpini(idm, jdm, kdm), sini(idm, jdm, kdm), tini(idm, jdm, kdm), &
              kvechalf(kdm + 1), uscaley(idm, jdm), vscalex(idm, jdm), &
              udepth(idm, jdm), vdepth(idm, jdm), basin(idm, jdm), stat=status)
    if (status /= 0) stop 'cannot ALLOCATE enough memory (1)'

    forall (i=1:idm) xvec(i) = i
    forall (j=1:jdm) yvec(j) = j
    forall (k=1:kdm) kvec(k) = k - 0.5
    forall (k=1:kdm + 1) kvechalf(k) = k - 1

    ! Open grid file
    status = nf90_open(trim(griddata)//trim(ocngridfile), nf90_nowrite, ncid)
    call handle_ncerror(status)

    ! Read grid cell mask, area and bathymetry
    status = nf90_inq_varid(ncid, 'pdepth', rhid)
    call handle_ncerror(status)
    status = nf90_get_var(ncid, rhid, pdepth)
    call handle_ncerror(status)
    status = nf90_inq_varid(ncid, 'udepth', rhid)
    call handle_ncerror(status)
    status = nf90_get_var(ncid, rhid, udepth)
    call handle_ncerror(status)
    status = nf90_inq_varid(ncid, 'vdepth', rhid)
    call handle_ncerror(status)
    status = nf90_get_var(ncid, rhid, vdepth)
    call handle_ncerror(status)
    status = nf90_inq_varid(ncid, 'pmask', rhid)
    call handle_ncerror(status)
    status = nf90_get_var(ncid, rhid, pmask)
    call handle_ncerror(status)
    status = nf90_inq_varid(ncid, 'parea', rhid)
    call handle_ncerror(status)
    status = nf90_get_var(ncid, rhid, parea)
    call handle_ncerror(status)
    status = nf90_inq_varid(ncid, 'udy', rhid)
    call handle_ncerror(status)
    status = nf90_get_var(ncid, rhid, uscaley)
    call handle_ncerror(status)
    status = nf90_inq_varid(ncid, 'vdx', rhid)
    call handle_ncerror(status)
    status = nf90_get_var(ncid, rhid, vscalex)
    call handle_ncerror(status)
    parea = parea*pmask

    ! Read coordinates
    status = nf90_inq_varid(ncid, 'plon', rhid)
    call handle_ncerror(status)
    status = nf90_get_var(ncid, rhid, plon)
    call handle_ncerror(status)
    status = nf90_inq_varid(ncid, 'plat', rhid)
    call handle_ncerror(status)
    status = nf90_get_var(ncid, rhid, plat)
    call handle_ncerror(status)
    status = nf90_inq_varid(ncid, 'ulon', rhid)
    call handle_ncerror(status)
    status = nf90_get_var(ncid, rhid, ulon)
    call handle_ncerror(status)
    status = nf90_inq_varid(ncid, 'ulat', rhid)
    call handle_ncerror(status)
    status = nf90_get_var(ncid, rhid, ulat)
    call handle_ncerror(status)
    status = nf90_inq_varid(ncid, 'vlon', rhid)
    call handle_ncerror(status)
    status = nf90_get_var(ncid, rhid, vlon)
    call handle_ncerror(status)
    status = nf90_inq_varid(ncid, 'vlat', rhid)
    call handle_ncerror(status)
    status = nf90_get_var(ncid, rhid, vlat)
    call handle_ncerror(status)

    ! Read grid cell vertices
    status = nf90_inq_varid(ncid, 'pclon', rhid)
    call handle_ncerror(status)
    status = nf90_get_var(ncid, rhid, plon_crns)
    call handle_ncerror(status)
    status = nf90_inq_varid(ncid, 'pclat', rhid)
    call handle_ncerror(status)
    status = nf90_get_var(ncid, rhid, plat_crns)
    call handle_ncerror(status)
    status = nf90_inq_varid(ncid, 'uclon', rhid)
    call handle_ncerror(status)
    status = nf90_get_var(ncid, rhid, ulon_crns)
    call handle_ncerror(status)
    status = nf90_inq_varid(ncid, 'uclat', rhid)
    call handle_ncerror(status)
    status = nf90_get_var(ncid, rhid, ulat_crns)
    call handle_ncerror(status)
    status = nf90_inq_varid(ncid, 'vclon', rhid)
    call handle_ncerror(status)
    status = nf90_get_var(ncid, rhid, vlon_crns)
    call handle_ncerror(status)
    status = nf90_inq_varid(ncid, 'vclat', rhid)
    call handle_ncerror(status)
    status = nf90_get_var(ncid, rhid, vlat_crns)
    call handle_ncerror(status)

    ! Permute to compensate for dimension bug in CMOR
    do j = 1, jdm
      do i = 1, idm
        do n = 1, ncrns
          plon_crnsp(n, i, j) = plon_crns(i, j, n)
          plat_crnsp(n, i, j) = plat_crns(i, j, n)
          ulon_crnsp(n, i, j) = ulon_crns(i, j, n)
          ulat_crnsp(n, i, j) = ulat_crns(i, j, n)
          vlon_crnsp(n, i, j) = vlon_crns(i, j, n)
          vlat_crnsp(n, i, j) = vlat_crns(i, j, n)
          if (plon_crnsp(n, i, j) < 0.) &
            plon_crnsp(n, i, j) = plon_crnsp(n, i, j) + 360
          if (ulon_crnsp(n, i, j) < 0.) &
            ulon_crnsp(n, i, j) = ulon_crnsp(n, i, j) + 360
          if (vlon_crnsp(n, i, j) < 0.) &
            vlon_crnsp(n, i, j) = vlon_crnsp(n, i, j) + 360
        end do
        if (plon(i, j) < 0.) plon(i, j) = plon(i, j) + 360
        if (ulon(i, j) < 0.) ulon(i, j) = ulon(i, j) + 360
        if (vlon(i, j) < 0.) vlon(i, j) = vlon(i, j) + 360
      end do
    end do

    ! Close grid file
    status = nf90_close(ncid)
    call handle_ncerror(status)

    ! Read initial layer profile from inicon.nc
    status = nf90_open(trim(griddata)//trim(ocninitfile), nf90_nowrite, ncid)
    call handle_ncerror(status)

    status = nf90_inq_varid(ncid, 'dp', rhid)
    call handle_ncerror(status)
    status = nf90_get_var(ncid, rhid, dpini)
    call handle_ncerror(status)
    status = nf90_inq_varid(ncid, 'saln', rhid)
    call handle_ncerror(status)
    status = nf90_get_var(ncid, rhid, sini)
    call handle_ncerror(status)
    status = nf90_inq_varid(ncid, 'temp', rhid)
    call handle_ncerror(status)
    status = nf90_get_var(ncid, rhid, tini)
    call handle_ncerror(status)
    status = nf90_inq_varid(ncid, 'pbot', rhid)
    call handle_ncerror(status)
    status = nf90_get_var(ncid, rhid, bpini)
    call handle_ncerror(status)

    ! global ocean volume and area
    status = nf90_inq_varid(ncid, 'volgs', rhid)
    call handle_ncerror(status)
    status = nf90_get_var(ncid, rhid, voglb)
    call handle_ncerror(status)
    aoglb = sum(parea)
!   write(*,*) 'volglb,aoglb:',voglb,aoglb
!   write(*,*) 'volglb/aoglb:',voglb/aoglb

    status = nf90_close(ncid)
    call handle_ncerror(status)

    ! Compute nitial global mean density
    rhoglb0 = 0.
    dpini = dpini*1.e-4     ! pa->dbar
    do j = 1, jdm
      do i = 1, idm
        if (pmask(i,j) == 0) cycle
        dptmp = 0.
        do k = 1, kdm
        if (tini(i,j,k)>=1.e20) cycle
          dptmp  = dptmp+0.5*dpini(i,j,k)   ! mid-layer pressure
          rhoglb0 = rhoglb0 + dpini(i,j,k)*rho(dptmp, dble(tini(i,j,k)), sref)
          ptmp = ptmp + dpini(i,j,k)
        end do
      end do
    end do
    rhoglb0 = rhoglb0/ptmp


  end subroutine read_gridinfo_ifile

  ! -----------------------------------------------------------------

  subroutine open_ofile(ivnm, ovnm, fx)

    implicit none

    logical, optional, intent(in)   :: fx
    logical                         :: fxflag

    character(len=*), intent(in)    :: ivnm, ovnm

    integer, parameter              :: ndimmax = 10
    integer                 :: i, j, k, n, ndims, dimids(ndimmax), dimlens(ndimmax)
    character(len=slenmax)  :: coord

    real(r8), allocatable       :: tmp1d(:), tmp2d(:, :)

    ! Check if output variable should have time coordinate
    fxflag = .false.
    if (present(fx)) then
      if (fx) fxflag = .true.
    end if

    ! Inquire variable units and dimensions in input file
    status = nf90_open(fnm, nf90_nowrite, ncid)
    call handle_ncerror(status)

    status = nf90_inq_varid(ncid, trim(ivnm), rhid)
    if (status /= nf90_noerr) then
      write (*, *) 'cannot find input variable ', trim(ivnm)
      stop
    end if
    status = nf90_inquire_variable(ncid, rhid, ndims=ndims)
    call handle_ncerror(status)
    status = nf90_inquire_variable(ncid, rhid, dimids=dimids(1:ndims))
    call handle_ncerror(status)
    dimlens = 1
    do n = 1, ndims
      status = nf90_inquire_dimension(ncid, dimids(n), len=dimlens(n))
      call handle_ncerror(status)
    end do
    if (.not. allocated(dp)) allocate (dp(idm, jdm, kdm))
    if (allocated(fld)) deallocate (fld, fld2, fldacc, fldtmp)
    ii = idm
    jj = jdm
    kk = kdm
    if (verbose) then
      write (*, *) 'ivm:', trim(ivnm)
      write (*, *) 'ovnm:', trim(ovnm)
      write (*, *) 'dimlens:', dimlens
      write(*, *) 'kdm:', kdm
    end if
    if (dims(1:25) == 'longitude,latitude,olevel') then
      vtype = 'level'
      kk = ddm
    else if (dims == 'longitude,latitude,time' .or. dims == 'longitude,latitude' .or. &
             dims(1:29) == 'longitude,latitude,time,depth' .or. &
             dims       == 'longitude,latitude,time,deltasigt') then
      vtype = '2d'
      kk = 1
      if (dimlens(3) .eq. kdm .and. kdm>0) THEN
        kk = kdm
      else if (dimlens(3) .eq. ddm .and. ddm>0) THEN
        kk = ddm
      end if
    else if (dims(1:30) == 'longitude,latitude,time,olayer') then
      vtype = 'olayer'
      kk = 1
    else if (dims == 'longitude,latitude,time,op20bar') then
      vtype = 'op20bar'
      kk = 1
    else if (dims == 'longitude,latitude,time,osurf') then
      vtype = 'ols'
      kk = 1
      if (dimlens(3) .eq. kdm .and. kdm>0) THEN
        kk = kdm
      else if (dimlens(3) .eq. ddm .and. ddm>0) THEN
        kk = ddm
      end if
    else if (dims == 'latitude,rho,basin,time') then
      vtype = 'merk'
      ii = ldm
      jj = kdm
      kk = rdm
    else if (dims == 'latitude,olevel,basin,time') then
      vtype = 'merd'
      ii = ldm
      jj = ddm
      kk = rdm
    else if (dims == 'latitude,basin,time') then
      vtype = 'mert'
      ii = ldm
      jj = rdm
      kk = 1
    else if (dims == 'oline,time') then
      vtype = 'sect'
      ii = sdm
      jj = 1
      kk = 1
    else if (dims == 'time') then
      vtype = '1d'
      ii = 1
      jj = 1
      kk = 1
      if (dimlens(1) .eq. idm .and. idm>0) ii = idm
      if (dimlens(2) .eq. jdm .and. jdm>0) jj = idm
      if (dimlens(3) .eq. kdm .and. kdm>0) THEN
        kk = kdm
      else if (dimlens(3) .eq. ddm .and. ddm>0) THEN
        kk = ddm
      end if
    else
      write (*, *) 'Undefined variable type, please check!'
    end if
    write (*, *) 'vtype:', trim(vtype)
    write (*, *) 'ii,jj,kk:', ii, jj, kk
    allocate (fld(ii, jj, kk), fld2(ii, jj, kk), fldacc(ii, jj, kk), &
              fldtmp(ii, jj, kk), stat=status)
    if (status /= 0) stop 'cannot ALLOCATE enough memory (4)'

    ! vunits has default value from data table
!   if (len_trim(vunits) == 0) then
!     status = nf90_get_att(ncid, rhid, 'units', vunits)
!     call handle_ncerror(status)
!     if (trim(vunits) == 'mm/s') vunits = 'kg m-2 s-1'
!   end if

    coord = ' '
    status = nf90_get_att(ncid, rhid, 'coordinates', coord)
    if (status /= nf90_noerr) coord(1:1) = ivnm(1:1)

    status = nf90_close(ncid)
    call handle_ncerror(status)

    ! Derive path of CMOR table
    tablepath = trim(tabledir)//trim(table)

    ! Inquire time dimension of output variable
    if (.not. fxflag) call json_get_timecoord(trim(tablepath), ovnm, tcoord)

    ! Call CMOR setup
    if (verbose) then
      if (createsubdirs) then
        error_flag = cmor_setup(inpath=trim(ibasedir), &
                                netcdf_file_action=CMOR_REPLACE_4, set_verbosity=CMOR_NORMAL, &
                                exit_control=CMOR_EXIT_ON_WARNING, &
                                create_subdirectories=1)
      else
        error_flag = cmor_setup(inpath=trim(ibasedir), &
                                netcdf_file_action=CMOR_REPLACE_4, set_verbosity=CMOR_NORMAL, &
                                exit_control=CMOR_EXIT_ON_WARNING, &
                                create_subdirectories=0)
      end if
    else
      if (createsubdirs) then
        error_flag = cmor_setup(inpath=trim(ibasedir), &
                                netcdf_file_action=CMOR_REPLACE_4, set_verbosity=CMOR_QUIET, &
                                create_subdirectories=1)
      else
        error_flag = cmor_setup(inpath=trim(ibasedir), &
                                netcdf_file_action=CMOR_REPLACE_4, set_verbosity=CMOR_QUIET, &
                                create_subdirectories=0)
      end if
    end if
    if (error_flag /= 0) stop 'Problem setting up CMOR'

    ! Derive path to CMOR table
    tablepath = trim(tabledir)//trim(table)

    ! Define output dataset
    grid_label = ocngrid_label
    grid = trim(ocngrid)
    if (trim(vtype) == 'layer' ) then
      grid = trim(ocngrid)//', vertical density coordinate'
    else if (trim(vtype) == 'olayer' ) then
      grid = trim(ocngrid)//', at specified vertical depth'
    else if (trim(vtype) == '1d' ) then
      grid = 'global mean or integral'
    else if (trim(vtype) == 'level' ) then
      grid = trim(ocngrid)//', hybrid coordinate remapped to z-levels'
    else if (trim(vtype) == 'merk' .or. trim(vtype) == 'merd' .or. trim(vtype) == 'mert') then
          !grid_label = 'grz'
          grid = 'zonal mean or integral'
    else if (trim(vtype) == 'sect') then
          !grid_label = 'grs'
          grid = 'section mean or integral' 
    end if
    call json_write_attributes(grid, grid_label, ocngrid_resolution, ovnm)
    error_flag = cmor_dataset_json(json_file_attributes)
    !call system('rm '//trim(json_file_attributes))

    ! Define horizontal axes
    !write(*, *) 'Define horizontal axes'
    if (vtype(1:3) /= 'mer' .and. vtype(1:3) /= 'sec') then
      iaxid = cmor_axis( &
              table=trim(tabledir)//'CMIP7_grids.json', &
              table_entry='i_index', &
              units='1', &
              length=idm, &
              coord_vals=xvec)
      jaxid = cmor_axis( &
              table=trim(tabledir)//'CMIP7_grids.json', &
              table_entry='j_index', &
              units='1', &
              length=jdm, &
              coord_vals=yvec)

      !write(*, *) 'Define horizontal grid '//coord(1:1)
      if (coord(1:1) == 'p') then
        grdid = cmor_grid( &
                axis_ids=(/iaxid, jaxid/), &
                latitude=plat, &
                longitude=plon, &
                latitude_vertices=plat_crnsp, &
                longitude_vertices=plon_crnsp)
      else if (coord(1:1) == 'u') then
        grdid = cmor_grid( &
                axis_ids=(/iaxid, jaxid/), &
                latitude=ulat, &
                longitude=ulon, &
                latitude_vertices=ulat_crnsp, &
                longitude_vertices=ulon_crnsp)
      else if (coord(1:1) == 'v') then
        grdid = cmor_grid( &
                axis_ids=(/iaxid, jaxid/), &
                latitude=vlat, &
                longitude=vlon, &
                latitude_vertices=vlat_crnsp, &
                longitude_vertices=vlon_crnsp)
      end if
    end if

    if (vtype(1:3) == 'mer') then
      laxid = cmor_axis( &
              table=trim(tablepath), &
              table_entry='latitude', &
              units='degrees_north', &
              length=ldm, &
              coord_vals=slat, &
              cell_bounds=slat_bnds)
      raxid = cmor_axis( &
              table=trim(tablepath), &
              table_entry='basin', &
              units='1', &
              coord_vals=region1)
    end if

    ! Define vertical axis
    if (trim(vtype) == 'layer')then
      if (index(special, 'half') > 0) then
        kaxid = cmor_axis( &
                table=trim(tablepath), &
                table_entry='rho', &
                units='kg m-3', &
                length=kdm + 1, &
                coord_vals=1000.+sigmahalf, &
                cell_bounds=1000.+sigmahalf_bnds)
      else
        kaxid = cmor_axis( &
                table=trim(tablepath), &
                table_entry='rho', &
                units='kg m-3', &
                length=kdm, &
                coord_vals=1000.+sigma, &
                cell_bounds=1000.+sigma_bnds)
      end if
    else if (trim(vtype) == 'level') then
      kaxid = cmor_axis( &
              table=trim(tablepath), &
              table_entry='depth_coord', &
              units='m', &
              length=ddm, &
              coord_vals=depth, &
              cell_bounds=depth_bnds)
    else if (trim(vtype) == 'olayer') then
      if (index(special, 'dzavg300m') > 0) then
        kaxid = cmor_axis( &
                table=trim(tablepath), &
                table_entry='olayer300m', &
                units='m', &
                length=1, &
                coord_vals=(/150./), &
                cell_bounds=(/0., 300./))
      else if (index(special, 'dzavg700m') > 0) then
        kaxid = cmor_axis( &
                table=trim(tablepath), &
                table_entry='olayer700m', &
                units='m', &
                length=1, &
                coord_vals=(/350./), &
                cell_bounds=(/0., 700./))
      else if (index(special, 'dzavg2000m') > 0) then
        kaxid = cmor_axis( &
                table=trim(tablepath), &
                table_entry='olayer2000m', &
                units='m', &
                length=1, &
                coord_vals=(/1000./), &
                cell_bounds=(/0., 2000./))
      else
        write(*,*) 'Error: olayer depth not supported'
        write(*,*) 'special: ', trim(special)
      end if
    else if (vtype == 'op20bar') then
      kaxid = cmor_axis( &
              table=trim(tablepath), &
              table_entry='op20bar', &
              units='bar', &
              length=1, &
              coord_vals=(/20./))
             !coord_vals=(/20./), &     ! omit bounds;
             !cell_bounds=(/20., 20./)) ! value close to 200m at hybrid coordinate.
    else if (vtype == 'ols') then
      kaxid = cmor_axis( &
              table=trim(tablepath), &
              table_entry='osurf', &
              units='', &
              length=1, &
              coord_vals=(/0./), &
              cell_bounds=(/0., 0./))
    else if (trim(vtype) == 'merd') then
      kaxid = cmor_axis( &
              table=trim(tablepath), &
              table_entry='depth_coord', &
              units='m', &
              length=ddm, &
              coord_vals=depth, &
              cell_bounds=depth_bnds)
    else if (trim(vtype) == 'merk') then
      kaxid = cmor_axis( &
              table=trim(tablepath), &
              table_entry='rho', &
              units='kg m-3', &
              length=kdm, &
              coord_vals=sigma + 1000., &
              cell_bounds=sigma_bnds + 1000.)
!   else if (trim(zcoord) == 'olevel') then
!     allocate (tmp1d(1), tmp2d(2, 1))
!     tmp1d(:) = (/5.d0/)
!     tmp2d(:, 1) = (/0.d0, 10.d0/)
!     kaxid = cmor_axis( &
!             table=trim(tablepath), &
!             table_entry='depth_coord', &
!             units='m', &
!             length=1, &
!             coord_vals=tmp1d, &
!             cell_bounds=tmp2d)
!     deallocate (tmp1d, tmp2d)
    else if (vtype(1:4) == 'sect') then
      saxid = cmor_axis( &
              table=trim(tablepath), &
              table_entry='oline', &
              units='1', &
              coord_vals=section1)
    end if

    ! Define time axis
    if (.not. fxflag) then
      if(verbose) then
        write(*, *) 'Define time axis '
        write(*, *) 'tablepath:table_entry:', trim(tablepath),':',trim(tcoord)
        write (*, *) 'tcoord:', trim(tcoord)
        write(*, *) 'calunits:', trim(calunits)
      end if
      taxid = cmor_axis( &
              table=trim(tablepath), &
              table_entry=trim(tcoord), &
              units=trim(calunits), &
              length=1)
    end if

    ! Define output variable
    if (verbose) then
      write(*, *) 'Define output variable'
      write (*, *) 'zcoord:', trim(zcoord)
      write (*, *) 'vunits:', trim(vunits)
    end if
    if (fxflag) then
      if (trim(vtype) == '2d') then
        varid = cmor_variable( &
                table=trim(tablepath), &
                table_entry=trim(ovnm), &
                units=trim(vunits), &
                axis_ids=(/grdid/), &
                missing_value=1e20, &
                history=trim(vhistory), &
                comment=trim(vcomment), &
                original_name=trim(original_name))
      else if (trim(vtype) == '1d') then
        varid = cmor_variable( &
                table=trim(tablepath), &
                table_entry=trim(ovnm), &
                units=trim(vunits), &
                axis_ids=(/taxid/), &
                original_name=trim(original_name), &
                missing_value=1e20, &
                history=trim(vhistory), &
                comment=trim(vcomment), &
                positive=trim(vpositive))
      else if (trim(vtype) == 'level') then
        varid = cmor_variable( &
                table=trim(tablepath), &
                table_entry=trim(ovnm), &
                units=trim(vunits), &
                axis_ids=(/grdid, kaxid/), &
                missing_value=1e20, &
                history=trim(vhistory), &
                comment=trim(vcomment), &
                original_name=trim(original_name))
      else 
        write(*,*) 'Error: variable type not supported for fx variable'
        write(*,*) 'vtype: ', trim(vtype)
      end if
    else
      if (trim(vtype) == '2d') then
        varid = cmor_variable( &
                table=trim(tablepath), &
                table_entry=trim(ovnm), &
                units=trim(vunits), &
                axis_ids=(/grdid, taxid/), &
                original_name=trim(original_name), &
                missing_value=1e20, &
                history=trim(vhistory), &
                comment=trim(vcomment), &
                positive=trim(vpositive))
      else if (trim(vtype) == 'layer' .or. trim(vtype) == 'level' .or. vtype(1:6) == 'olayer' &
        .or. trim(vtype) == 'ols' .or. trim(vtype) == 'op20bar') then
        varid = cmor_variable( &
                table=trim(tablepath), &
                table_entry=trim(ovnm), &
                units=trim(vunits), &
                axis_ids=(/grdid, kaxid, taxid/), &
                original_name=trim(original_name), &
                missing_value=1e20, &
                positive=trim(vpositive), &
                history=trim(vhistory), &
                comment=trim(vcomment))
      else if (vtype(1:4) == 'merd' .or. vtype(1:4) == 'merk') then
        varid = cmor_variable( &
                table=trim(tablepath), &
                table_entry=trim(ovnm), &
                units=trim(vunits), &
                axis_ids=(/laxid, kaxid, raxid, taxid/), &
                original_name=trim(original_name), &
                missing_value=1e20, &
                history=trim(vhistory), &
                comment=trim(vcomment), &
                positive=trim(vpositive))
      else if (vtype(1:4) == 'mert') then
        varid = cmor_variable( &
                table=trim(tablepath), &
                table_entry=trim(ovnm), &
                units=trim(vunits), &
                axis_ids=(/laxid, raxid, taxid/), &
                original_name=trim(original_name), &
                missing_value=1e20, &
                history=trim(vhistory), &
                comment=trim(vcomment), &
                positive=trim(vpositive))
      else if (vtype(1:4) == 'sect') then
        varid = cmor_variable( &
                table=trim(tablepath), &
                table_entry=trim(ovnm), &
                units=trim(vunits), &
                axis_ids=(/saxid, taxid/), &
                original_name=trim(original_name), &
                missing_value=1e20, &
                history=trim(vhistory), &
                comment=trim(vcomment), &
                positive=trim(vpositive))
      else if (vtype(1:2) == '1d') then
        varid = cmor_variable( &
                table=trim(tablepath), &
                table_entry=trim(ovnm), &
                units=trim(vunits), &
                axis_ids=(/taxid/), &
                original_name=trim(original_name), &
                missing_value=1e20, &
                history=trim(vhistory), &
                comment=trim(vcomment), &
                positive=trim(vpositive))
      else
        write(*,*) 'Error: variable type not supported for time-dependent variable'
        write(*,*) 'vtype: ', trim(vtype)
      end if
    end if
#ifdef DEFLATE
    error_flag = cmor_set_deflate(varid, 1, 1, 5)
#endif

  end subroutine open_ofile

  ! -----------------------------------------------------------------

  subroutine close_ofile

    implicit none

    status = cmor_close(varid, fnmo, 1)
    if (status /= 0) stop 'problem closing CMOR output file'

  end subroutine close_ofile

  ! -----------------------------------------------------------------

  subroutine read_field

    implicit none

    integer                 :: i, j, k
    character(len=slenmax)  :: coord

    ! Open input file
    status = nf90_open(fnm, nf90_nowrite, ncid)
    call handle_ncerror(status)

    ! Read data

    fld = 0.

    if (allocated(sources)) then
      do k = 1, size(sources)
        call add_fixed(sources(k), factors(k), ncid)
      end do
    else
      call add_fixed(ivnm, 1.0_r8, ncid)
    end if

!   if (index(special, 'volcello') > 0) then
!     fld2 = fld
!     fld = 0.
!   end if

    status = nf90_close(ncid)
    call handle_ncerror(status)

  end subroutine read_field

  ! -----------------------------------------------------------------

  subroutine read_tslice(rec, badrec, fname)

    implicit none

    integer, intent(in)             :: rec
    logical, intent(out)            :: badrec
    character(len=*), intent(in), optional  :: fname
    integer, save                   :: fid
    integer                         :: i, j, k, rec1

    ! Exception for fill day
    rec1 = max(rec, 1)

    ! Open input file
    if (present(fname)) then
      status = nf90_open(fname, nf90_nowrite, fid)
      call handle_ncerror(status)
    else
      status = nf90_open(fnm, nf90_nowrite, fid)
      call handle_ncerror(status)
    end if

    if (.false.) then
      ! Read time information
      status = nf90_inq_varid(fid, 'time', rhid)
      if (status /= nf90_noerr) then
        write (*, *) 'cannot find time variable'
        stop
      end if
      status = nf90_get_var(fid, rhid, tval, (/rec1/), (/1/))
      call handle_ncerror(status)
      if (rec == 0) tval = tval - 1

      tbnds(1, 1) = max(0., tbnds(1, 1))
      tval = 0.5*(tbnds(1, 1) + tbnds(2, 1))
    end if

    ! Read data
    if (index(special, '2zostoga') > 0) then
      fld = 0.
      s1 = 'dp'
      call add_tslice(s1, 1.0_r8, rec1, fid)
      do k = 1, kk
        do j = 1, jj
          do i = 1, ii
            if (fld(i, j, k) == 1e20) then
              dp(i, j, k) = 0.
            else
              dp(i, j, k) = fld(i, j, k)
            end if
          end do
        end do
      end do
    end if

    if (index(special, 'dp.avg') > 0) then
      fld = 0.
      call add_tslice(sources(2), factors(2), rec1, fid)
      fld2 = fld
      fld = 0.
      call add_tslice(sources(1), factors(1), rec1, fid)
!   else if (index(special, 'pbot2dp') > 0) then
!     fld = 0.
    else
      fld = 0.
      do k = 1, size(sources)
        call add_tslice(sources(k), factors(k), rec1, fid)
      end do
    end if

    ! Read sea level height if necessary
    if (index(special, 'dz2') > 0) then
      status = nf90_inq_varid(fid, 'sealv', rhid)
      if (status /= nf90_noerr) then
        write (*, *) 'cannot find input variable sealv '
        stop
      end if
      status = nf90_get_var(fid, rhid, sealv, (/1, 1, rec1/), (/idm, jdm, 1/))
      call handle_ncerror(status)
      status = nf90_get_att(fid, rhid, 'scale_factor', sfac)
      if (status /= nf90_noerr) sfac = 1.
      status = nf90_get_att(fid, rhid, 'add_offset', offs)
      if (status /= nf90_noerr) offs = 0.
      status = nf90_get_att(fid, rhid, '_FillValue', fill)
      do j = 1, jj
        do i = 1, ii
          if (sealv(i, j) == fill) then
            sealv(i, j) = 1e20
          else
            sealv(i, j) = sealv(i, j)*sfac + offs
          end if
        end do
      end do
    end if

    ! Read bottom pressure if necessary
    if (index(special, 'dzavg') > 0 .or. index(special, 'pbot2dp') > 0) then
      status = nf90_inq_varid(fid, 'pbot', rhid)
      if (status /= nf90_noerr) then
        write (*, *) 'cannot find input variable pbot '
        stop
      end if
      status = nf90_get_var(fid, rhid, pbot, (/1, 1, rec1/), (/idm, jdm, 1/))
      call handle_ncerror(status)
      status = nf90_get_att(fid, rhid, 'scale_factor', sfac)
      if (status /= nf90_noerr) sfac = 1.
      status = nf90_get_att(fid, rhid, 'add_offset', offs)
      if (status /= nf90_noerr) offs = 0.
      status = nf90_get_att(fid, rhid, '_FillValue', fill)
      do j = 1, jj
        do i = 1, ii
          if (pbot(i, j) == fill) then
            pbot(i, j) = 1e20
          else
            pbot(i, j) = pbot(i, j)*sfac + offs
          end if
        end do
      end do
    end if

    status = nf90_close(fid)
    call handle_ncerror(status)

  end subroutine read_tslice

  ! -----------------------------------------------------------------

  subroutine add_tslice(vnm, fac, rec, fid)

    ! Description: add one time slice to output variable fld

    implicit none

    character(len=slenmax), intent(in)  :: vnm
    real(r8), intent(in)                :: fac
    integer, intent(in)                 :: rec, fid
    integer                             :: i, j, k

    ! Return if variable name is empty
    if (len(trim(vnm)) == 0) return

    ! Read time slice
    status = nf90_inq_varid(fid, trim(vnm), rhid)
    if (status /= nf90_noerr) then
      write (*, *) 'cannot find input variable ', trim(vnm)
      stop
    end if
    if (trim(vtype) == '2d' .or.vtype == 'op20bar' .or. vtype == 'ols' .or. vtype(1:6) == 'olayer') then
      if (kk == 1) then
        status = nf90_get_var(fid, rhid, fldtmp, (/1, 1, rec/), (/ii, jj, 1/))
      else
        status = nf90_get_var(fid, rhid, fldtmp, (/1, 1, 1, rec/), (/ii, jj, kk, 1/))
      end if
    else if (trim(vtype) == '1d') then
      if (kk > 1 ) then
        status = nf90_get_var(fid, rhid, fldtmp, (/1, 1, 1, rec/), (/ii, jj, kk, 1/))
      else
        status = nf90_get_var(fid, rhid, fldtmp, (/rec/), (/1/))
      end if
!   else if (trim(vtype) == 'layer') then
!     status = nf90_get_var(fid, rhid, fldtmp, (/1, 1, 1, rec/), (/idm, jdm, kdm, 1/))
    else if (trim(vtype) == 'level') then
      status = nf90_get_var(fid, rhid, fldtmp, (/1, 1, 1, rec/), (/idm, jdm, ddm, 1/))
    else if (trim(vtype) == 'merk') then
      status = nf90_get_var(fid, rhid, fldtmp, (/1, 1, 1, rec/), (/ldm, kdm, rdm, 1/))
    else if (trim(vtype) == 'merd') then
      status = nf90_get_var(fid, rhid, fldtmp, (/1, 1, 1, rec/), (/ldm, ddm, rdm, 1/))
    else if (trim(vtype) == 'mert') then
      status = nf90_get_var(fid, rhid, fldtmp, (/1, 1, rec/), (/ldm, rdm, 1/))
    else if (trim(vtype) == 'sect') then
      status = nf90_get_var(fid, rhid, fldtmp, (/1, rec/), (/sdm, 1/))
    end if
    call handle_ncerror(status)
    status = nf90_get_att(fid, rhid, 'scale_factor', sfac)
    if (status /= nf90_noerr) sfac = 1.
    status = nf90_get_att(fid, rhid, 'add_offset', offs)
    if (status /= nf90_noerr) offs = 0.
    status = nf90_get_att(fid, rhid, '_FillValue', fill)
    if (status /= nf90_noerr) then
      do k = 1, kk
        do j = 1, jj
          do i = 1, ii
            fld(i, j, k) = fld(i, j, k) + (fldtmp(i, j, k)*sfac + offs)*fac
          end do
        end do
      end do
    else
      do k = 1, kk
        do j = 1, jj
          do i = 1, ii
            if (fldtmp(i, j, k) == fill) then
              fld(i, j, k) = 1e20
            else
              fld(i, j, k) = fld(i, j, k) + (fldtmp(i, j, k)*sfac + offs)*fac
            end if
          end do
        end do
      end do
    end if
    ! replace fill with 'where' function?

  end subroutine add_tslice

  ! -----------------------------------------------------------------

  subroutine add_fixed(vnm, fac, fid)

    ! Description: add one time slice to output variable fld

    implicit none

    character(len=slenmax), intent(in)  :: vnm
    real(r8), intent(in)                :: fac
    integer, intent(in)                 :: fid
    integer                             :: i, j, k

    ! Return if variable name is empty
    if (len(trim(vnm)) == 0) return

    ! Read time slice
    status = nf90_inq_varid(fid, trim(vnm), rhid)
    if (status /= nf90_noerr) then
      write (*, *) 'cannot find input variable ', trim(vnm)
      stop
    end if
    status = nf90_get_var(fid, rhid, fldtmp)
    call handle_ncerror(status)
    status = nf90_get_att(fid, rhid, 'scale_factor', sfac)
    if (status /= nf90_noerr) sfac = 1.
    status = nf90_get_att(fid, rhid, 'add_offset', offs)
    if (status /= nf90_noerr) offs = 0.
    status = nf90_get_att(fid, rhid, '_FillValue', fill)
    if (status /= nf90_noerr) then
      do k = 1, kk
        do j = 1, jj
          do i = 1, ii
            fld(i, j, k) = fld(i, j, k) + (fldtmp(i, j, k)*sfac + offs)*fac
          end do
        end do
      end do
    else
      do k = 1, kk
        do j = 1, jj
          do i = 1, ii
            if (fldtmp(i, j, k) == fill) then
              fld(i, j, k) = 1e20
            else
              fld(i, j, k) = fld(i, j, k) + (fldtmp(i, j, k)*sfac + offs)*fac
            end if
          end do
        end do
      end do
    end if

  end subroutine add_fixed

  ! -----------------------------------------------------------------

  subroutine write_field

    implicit none

    integer :: i, j, k

    ! Set zero on ocean grid cells
    do k = 1, kk
      do j = 1, jj
        do i = 1, ii
          if (abs(fld(i, j, k)) > 2e20) fld(i, j, k) = 0.
        end do
      end do
    end do

    ! Store variable
    if (vtype == '2d') then
      error_flag = cmor_write( &
                   var_id=varid, &
                   data=reshape(fld, (/idm, jdm/)))
    else
      error_flag = cmor_write( &
                   var_id=varid, &
                   data=fld)
    end if

  end subroutine write_field

  ! -----------------------------------------------------------------

  subroutine write_tslice

    implicit none

    integer :: i, j, k

    ! Populate field defined at interface level
!   if (index(special, 'zhalf') > 0) then
!     fldhalf(:, :, 1) = sealv
!     fldhalf(:, :, 2:kdm + 1) = fld
!     do k = 1, kk + 1
!       do j = 1, jj
!         do i = 1, ii
!           if (abs(fldhalf(i, j, k)) > 2e20) fldhalf(i, j, k) = 0.
!         end do
!       end do
!     end do
!   else if (index(special, 'halfl') > 0) then
!     fldhalf(:, :, 2:kdm + 1) = fld
!     do j = 1, jj
!       do i = 1, ii
!         if (abs(fldhalf(i, j, 2)) >= 1e20) then
!           fldhalf(i, j, 1) = 1e20
!         else
!           fldhalf(i, j, 1) = 0.
!         end if
!       end do
!     end do
!   end if

    ! Set missing on land grid cells
    !if (index(special, 'glbave') <= 0) then
!   if (index(special, 'glbave') > 0) then
!     do k = 1, kk
!       do j = 1, jj
!         do i = 1, ii
!           if (abs(fld(i, j, k)) > 1e20) fld(i, j, k) = 1e20
!         end do
!       end do
!     end do
!   end if

    ! Store variable
!   if (index(special, 'half') > 0) then
!     if (trim(tcoord) == 'time1') then
!       error_flag = cmor_write( &
!                    var_id=varid, &
!                    data=fldhalf, &
!                    ntimes_passed=1, &
!                    time_vals=tval)
!     else
!       error_flag = cmor_write( &
!                    var_id=varid, &
!                    data=fldhalf, &
!                    ntimes_passed=1, &
!                    time_vals=tval, &
!                    time_bnds=tbnds)
!     end if
!   else
      if (trim(tcoord) == 'time1') then
        error_flag = cmor_write( &
                     var_id=varid, &
                     data=fld, &
                     ntimes_passed=1, &
                     time_vals=tval)
      else
!       if ((lsumz .or. index(special, 'level1') > 0) .and. &
!           .not. index(special, 'glbave') > 0 &
!           .or. index(special, 'lvl2srf') > 0 &
!           .or. index(special, 'dpint') > 0 &
!           .or. index(special, 'dp.avg') > 0 &
!           .or. index(special, 'locmin') > 0 &
!           .or. index(special, 'omega2z') > 0) then

!         print *, shape(fld)           ! Add before cmor_write
!         print *, lbound(fld), ubound(fld)

        if (vtype == '2d' ) then
          error_flag = cmor_write( &
                       var_id=varid, &
                       data=fld(:, :, 1), &
                       ntimes_passed=1, &
                       time_vals=tval, &
                       time_bnds=tbnds)
        else if (vtype == 'op20bar' .or. vtype == 'ols' .or. vtype(1:6) == 'olayer') then
          error_flag = cmor_write( &
                       var_id=varid, &
                       data=fld(:, :, 1), &
                       ntimes_passed=1, &
                       time_vals=tval, &
                       time_bnds=tbnds)
        else if (vtype(1:2) == '1d') then
          error_flag = cmor_write( &
                       var_id=varid, &
                       data=(/fld(1, 1, 1)/), &
                       ntimes_passed=1, &
                       time_vals=tval, &
                       time_bnds=tbnds)
!       else if (index(special, 'dzavg') > 0) then
!         error_flag = cmor_write( &
!                      var_id=varid, &
!                      data=(reshape(fld(:, :, 1), (/idm, jdm, 1/))), &
!                      ntimes_passed=1, &
!                      time_vals=tval, &
!                      time_bnds=tbnds)
        else if (vtype(1:4) == 'sect') then
          error_flag = cmor_write( &
                       var_id=varid, &
                       data=fld(:, 1, 1), &
                       ntimes_passed=1, &
                       time_vals=tval, &
                       time_bnds=tbnds)
        else
          error_flag = cmor_write( &
                       var_id=varid, &
                       data=fld, &
                       ntimes_passed=1, &
                       time_vals=tval, &
                       time_bnds=tbnds)
        end if
      end if
!   end if

  end subroutine write_tslice

  ! -----------------------------------------------------------------

  subroutine select_ocn_ftag(realm, frequency, itag)

    character(len=*), intent(in) :: realm, frequency
    character(len=*), intent(out) :: itag

    select case (frequency)
    case ('mon')
      if (realm == 'ocean') itag = tagomon
      if (realm == 'ocnBgchem') itag = tagomonbgc
    case ('day')
      if (realm == 'ocean') itag = tagoday
      if (realm == 'ocnBgchem') itag = tagodaybgc
    case ('yr')
      if (realm == 'ocean') itag = tagoyr
      if (realm == 'ocnBgchem') itag = tagoyrbgc
    case default
      write(*,*) 'Error: Unknown realm: ',trim(realm)
    end select

  end subroutine select_ocn_ftag

end module m_modelsocn
