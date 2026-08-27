program read_json_dimensions
    use json_module, only: json_file, json_value
    use, intrinsic :: iso_fortran_env, only : dp => real64
    implicit none
    
    ! Declare JSON object
    type(json_file) :: json
    logical :: found
    character(len=:), allocatable :: str_val
    integer :: i, n
    !integer, parameter :: dp = selected_real_kind(15, 307)
    real(kind=dp),dimension(10)     :: array
    
    ! Variables to store dimension information
    character(len=10), dimension(:), allocatable :: dimensions, variables
    real, dimension(:), allocatable :: factors
    integer :: num_dims

    array = 1.0_dp

    !write(*,*) array

    call json%initialize(path_separator=':')
    
    ! Load JSON file
    call json%load_file('../recipes/template/variable_mapping_NorESM3_to_CMIP7.json')
    
    ! Check if load was successful
    if (json%failed()) then
        write(*,*) 'Error loading JSON file'
        stop
    end if
    
    ! Method 1: Get the entire dimensions array as a string
    call json%get('variable_entry:ocean.wfo.tavg-u-hxy-sea.mon.glb:sources:variables', variables, found)
    call json%get('variable_entry:ocean.wfo.tavg-u-hxy-sea.mon.glb:sources:factors', factors, found)
    
    write(*,*) 'variables:',variables
    write(*,*) 'factors:',factors
    ! Clean up
    call json%destroy()
   
    ! ---------------------- 
    ! Initialize JSON object
    call json%initialize(path_separator='.')
    
    ! Load JSON file
    call json%load_file('/diagnostics/CMOR/esm2cmor/tables/CMIP7_ocean.json')
    
    ! Check if load was successful
    if (json%failed()) then
        write(*,*) 'Error loading JSON file'
        stop
    end if
    
    ! Method 1: Get the entire dimensions array as a string
    write(*,*) '--- Method1: Get the entire dimensions array as a string --- '
    ! Note: json-fortran returns arrays as comma-separated strings
    !call json%get('variable_entry.tas_tavg-h2m-hxy-u.dimensions', str_val, found)
    !call json%get('variable_entry.tas_tavg-h2m-hxy-u.dimensions', dimensions, found)
    call json%get('variable_entry.thetao_tavg-ol-hxy-sea.dimensions', dimensions, found)
    
    if (found) then
        !write(*,*) 'Dimensions string: ', str_val
        write(*,*) 'Dimensions string: ', dimensions
        write(*,*) 'Dimension size: ', size(dimensions)
        write(*,*) 'Dimension 1: ', dimensions(1)
        write(*,*) 'Dimension 2: ', dimensions(2)
        write(*,*) 'Dimension 3: ', dimensions(3)
        write(*,*) 'Dimension 4: ', dimensions(4)
        write(*,*) 'len 1: ', len(trim(dimensions(1)))
        write(*,*) 'len 2: ', len(trim(dimensions(2)))
        write(*,*) 'len 3: ', len(trim(dimensions(3)))
        write(*,*) 'len 4: ', len(trim(dimensions(4)))
        
        ! Parse the comma-separated string into individual dimensions
        ! The string will be like: '["longitude","latitude","time","height2m"]'
        ! We need to parse this manually
!       call parse_dimensions_string(str_val, dimensions, num_dims)
!       
!       write(*,*) 'Number of dimensions: ', num_dims
!       write(*,*) 'Dimensions:'
!       do i = 1, num_dims
!           write(*,*) '  ', trim(dimensions(i))
!       end do
!       
!       ! Clean up
!       deallocate(dimensions)
    else
        write(*,*) 'Path not found in JSON'
    end if
    
    ! Alternative method: Access each dimension individually
    write(*,*) '--- Alternative method: Accessing individual elements ---'
    call json%get('variable_entry.tas_tavg-h2m-hxy-u.dimensions(1)', str_val, found)
    if (found) write(*,*) 'Dimension 1: ', str_val
    if (found) write(*,*) 'len(dim(1)): ', len(str_val)
    
    call json%get('variable_entry.tas_tavg-h2m-hxy-u.dimensions(2)', str_val, found)
    if (found) write(*,*) 'Dimension 2: ', str_val
    if (found) write(*,*) 'len(dim(2)): ', len(str_val)
    
    call json%get('variable_entry.tas_tavg-h2m-hxy-u.dimensions(3)', str_val, found)
    if (found) write(*,*) 'Dimension 3: ', str_val
    
    call json%get('variable_entry.tas_tavg-h2m-hxy-u.dimensions(4)', str_val, found)
    if (found) write(*,*) 'Dimension 4: ', str_val

    call json%get('variable_entry.tas_tavg-h2m-hxy-u.dimensions(5)', str_val, found)
    if (found) write(*,*) 'Dimension 5: ', str_val
    
    ! Clean up
    call json%destroy()
    
contains
    
    ! Subroutine to parse the dimensions string
    subroutine parse_dimensions_string(str, dims, n)
        character(len=*), intent(in) :: str
        character(len=:), allocatable, dimension(:), intent(out) :: dims
        integer, intent(out) :: n
        character(len=len(str)) :: temp_str
        integer :: i, j, start_pos, end_pos, count
        
        ! Remove brackets and quotes
        temp_str = adjustl(str)
        
        ! Remove leading '[' and trailing ']'
        if (temp_str(1:1) == '[') then
            temp_str = temp_str(2:)
        end if
        if (temp_str(len_trim(temp_str):len_trim(temp_str)) == ']') then
            temp_str = temp_str(:len_trim(temp_str)-1)
        end if
        
        ! Count number of dimensions (by counting commas)
        count = 1
        do i = 1, len_trim(temp_str)
            if (temp_str(i:i) == ',') count = count + 1
        end do
        
        n = count
        allocate(character(len=50) :: dims(n))
        
        ! Parse individual dimensions
        start_pos = 1
        count = 0
        do i = 1, len_trim(temp_str)
            if (temp_str(i:i) == ',' .or. i == len_trim(temp_str)) then
                count = count + 1
                if (i == len_trim(temp_str)) then
                    end_pos = i
                else
                    end_pos = i - 1
                end if
                
                ! Extract dimension name
                dims(count) = temp_str(start_pos:end_pos)
                
                ! Remove quotes
                dims(count) = trim(adjustl(dims(count)))
                if (dims(count)(1:1) == '"') then
                    dims(count) = dims(count)(2:)
                end if
                if (dims(count)(len_trim(dims(count)):len_trim(dims(count))) == '"') then
                    dims(count) = dims(count)(:len_trim(dims(count))-1)
                end if
                
                start_pos = i + 1
            end if
        end do
    end subroutine parse_dimensions_string

end program read_json_dimensions
