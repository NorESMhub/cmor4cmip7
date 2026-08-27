program get_json_keys
    use json_module
      use m_jsons
    implicit none

    type(json_file) :: jsonf
    type(json_core) :: jsonc
    type(json_value), pointer :: entry_ptr => null()
    type(json_value), pointer :: child_ptr => null()
    character(len=:), allocatable :: key_name
    character(len=:), allocatable :: value_str
    real, dimension(:), allocatable :: numbers
    character(len=120) :: string
    character(len=20),dimension(:), allocatable :: strings
    integer :: i, num_children
    integer :: var_type
    logical :: found

    call json_get_value('/diagnostics/CMOR/esm2cmor/tables/CMIP7_ocean.json','variable_entry:tos_tavg-u-hxy-sea:units',& 
                        string,found, ':')
    write(*,*) 'keys:',string

    call json_get_value('/diagnostics/CMOR/esm2cmor/tables/CMIP7_ocean.json','variable_entry.tos_tavg-u-hxy-sea.units',& 
                        string,found)
    write(*,*) 'keys:',string

    call json_get_timecoord('/diagnostics/CMOR/esm2cmor/tables/CMIP7_ocean.json', &
                            'tos_tavg-u-hxy-sea', string, found)
    write(*,*) 'keys:',string

    stop 'line 22'

    ! 1. Initialize and load the file
    !call jsonc%initialize(path_separator=':')

    call jsonf%initialize(path_separator=':')
    call jsonf%load_file('../recipes/template/variable_mapping_NorESM3_to_CMIP7.json')
    if (jsonf%failed()) stop "Error: Could not load JSON file."

    ! 2. Locate the 'entry' object
    ! Use jsonf%get to find the pointer to the 'entry' block

    call jsonf%get('variable_entry:ocean.wfo.tavg-u-hxy-sea.mon.glb:preproc', entry_ptr)

    call jsonf%get('variable_entry:atmos.tas.tavg-h2m-hxy-u.mon.glb:original_name', key_name, found)
    write(*,*) 'key_name:',key_name

    call jsonf%get('variable_entry:ocean.wfo.tavg-u-hxy-sea.mon.glb:sources:factors', numbers, found)
    call jsonf%get('variable_entry:ocean.wfo.tavg-u-hxy-sea.mon.glb:sources:variables', strings, found)
    do i = 1, size(strings)
        write(*,*) trim(strings(i)),':',numbers(i)
    end do

    !call jsonf%get('entry:ocean.wfo.tavg-u-hxy-sea.mon.glb:sources:variables', str, found)
    !call jsoncf%get('entry:ocean.wfo.tavg-u-hxy-sea.mon.glb:preproc:units', str, found)

    if (associated(entry_ptr)) then
        ! 3. Get the number of keys (children) under 'entry'
        call jsonc%info(entry_ptr, n_children=num_children)
        
        print *, "Found ", num_children, " keys in 'variable_entry':"
        
        ! 4. Loop through children to extract their names
        do i = 1, num_children
            ! Get pointer to the i-th child (1-based index)
            call jsonc%get_child(entry_ptr, i, child_ptr)
            
            ! Extract the name (key) of this child
            call jsonc%info(child_ptr, name=key_name)

            call jsonc%info(child_ptr, var_type=var_type)

            select case (var_type)
            case (json_integer)
                print *, "Element", i, "is an Integer"
            case (json_null)
                print *, "Element", i, "is Null"
            case (json_string)
                print *, "Element", i, "is String"
            case default
                print *, "Element", i, "is another type"
            end select


!json_unknown
!json_null
!json_object
!json_array
!json_logical
!json_integer
!json_real
!json_string

            
            print *, "Key ", i, ": ", key_name
            call jsonf%get('variable_entry:ocean.wfo.tavg-u-hxy-sea.mon.glb:preproc:'//key_name, value_str)
            print *, "value: ", value_str
        end do
    else
        print *, "Error: 'variable_entry' key not found in JSON."
    end if

    ! 5. Cleanup
    call jsonf%destroy()

contains

    subroutine json_parser_mapping_keys(fnm,path)

    character(len=*), intent(in) :: fnm, path

    type(json_file) :: jsonf
    type(json_core) :: jsonc
    type(json_value), pointer :: entry_ptr => null()
    type(json_value), pointer :: child_ptr => null()

    integer :: i, num_children
    logical :: found
!   integer :: k, pdm

    character(len=:), allocatable :: key_name
    character(len=100), dimension(:), allocatable :: strings

    call jsonf%initialize(path_separator=':')
    call jsonf%load_file(filename=trim(fnm))
    if (jsonf%failed()) stop "Error: Could not load JSON file."//fnm
    call jsonf%get(path, entry_ptr)
    !call jsonf%destroy()

    if (associated(entry_ptr)) then
      ! get the number of keys (children)
      call jsonc%info(entry_ptr, n_children=num_children)

      print *, "Found ", num_children, " keys in 'variable_entry':"

      ! 4. Loop through children to extract their names
      do i = 1, num_children
          ! Get pointer to the i-th child (1-based index)
          call jsonc%get_child(entry_ptr, i, child_ptr)

          ! Extract the name (key) of this child
          call jsonc%info(child_ptr, name=key_name)

          print *, "Key ", i, ": ", key_name
          !call jsonf%get('variable_entry:ocean.wfo.tavg-u-hxy-sea.mon.glb:preproc:'//key_name, value_str)
          !print *, "value: ", value_str
      end do
    else
        print *, "Error: 'variable_entry' key not found in JSON."
    end if

    ! 5. Cleanup
    call jsonf%destroy()
    end subroutine json_parser_mapping_keys

end program get_json_keys

