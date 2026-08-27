program read_variables
    implicit none

    ! Maximum expected number of entries (adjust if needed)
    integer, parameter :: max_entries = 200
    ! Length of each character string (long enough for the given data)
    integer, parameter :: str_len = 100

    ! Namelist variable
    character(len=str_len) :: compound_names(max_entries)

    ! Local variables
    integer :: i, n_entries, io_status
    namelist /variables/ compound_names

    ! Initialize array to empty strings
    compound_names = ''

    ! Open the namelist file
    open(unit=10, file='variables.nml', status='old', action='read', &
         iostat=io_status)
    if (io_status /= 0) then
        print *, 'Error: Could not open file "vars2cmor.nml".'
        stop
    end if

    ! Read the namelist
    read(10, nml=variables, iostat=io_status)
    if (io_status /= 0) then
        print *, 'Error: Failed to read namelist "vars2cmor".'
        close(10)
        stop
    end if

    close(10)

    ! Count how many entries were actually read (non‑blank)
    n_entries = 0
    do i = 1, max_entries
        if (len_trim(compound_names(i)) > 0) then
            n_entries = n_entries + 1
        else
            exit   ! First blank entry marks the end
        end if
    end do

    ! Output the results
    print *, 'Number of variables read: ', n_entries
    do i = 1, n_entries
        !print *, 'len:',len(trim(ivnm(i))),trim(ivnm(i))
        print *, trim(compound_names(i))
    end do

end program read_variables
