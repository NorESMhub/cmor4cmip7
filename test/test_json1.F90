program read_json_simple
    use json_module, only: json_file, json_value
    implicit none
    
    type(json_file) :: json
    logical :: found
    character(len=:), allocatable :: str_val
    integer :: i
    
    call json%initialize()
    call json%load_file('../tables/CMIP7_atmos.json')
    
    if (json%failed()) then
        write(*,*) 'Error loading JSON file'
        stop
    end if
    
    ! Get other related information
    call json%get('variable_entry.tas_tavg-h2m-hxy-u.long_name', str_val, found)
    if (found) write(*,*) 'Long name: ', str_val
    
    call json%get('variable_entry.tas_tavg-h2m-hxy-u.units', str_val, found)
    if (found) write(*,*) 'Units: ', str_val
    
    call json%get('variable_entry.tas_tavg-h2m-hxy-u.standard_name', str_val, found)
    if (found) write(*,*) 'Standard name: ', str_val
    
    ! Method to iterate through dimensions
    write(*,*) 'Dimensions found:'
    i = 1
    do
        ! Try to get each dimension
        call json%get('variable_entry.tas_tavg-h2m-hxy-u.dimensions('//trim(adjustl(str(i)))//')', str_val, found)
        if (.not. found) exit
        write(*,*) '  Dimension ', i, ': ', trim(str_val)
        i = i + 1
    end do
    
    call json%destroy()
    
contains
    
    ! Helper function to convert integer to string
    character(len=20) function str(k)
        integer, intent(in) :: k
        write(str, '(I0)') k
    end function str

end program read_json_simple
