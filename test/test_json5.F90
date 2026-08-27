program read_entry_keys
    use json_module
    implicit none

    type(json_file) :: json
    type(json_value), pointer :: entry
    !character(len=:), allocatable :: keys(:)
    character(len=100), dimension(:), allocatable :: vars
    character(len=:), allocatable :: str_val
    integer :: i, n
    logical :: found
    character(len=100)      :: compound_name

    compound_name = 'ocean.wfo.tavg-u-hxy-sea.mon.glb'

    ! Initialize and load JSON file
    call json%initialize(path_separator=':')
    call json%load_file('../recipes/variable_mapping_NorESM3.json')

    if (json%failed()) then
        write(*,*) 'Error loading JSON file'
        stop
    end if

    ! Get the "entry" object
    !call json%get('entry', entry)
    !call json%get('entry', str_val, found)
    !call json%get('entry.tavg-h2m-hxy-u.original_name', str_val, found)
    !call json%get('entry:ocean.wfo.tavg-u-hxy-sea.mon.glb:sources:variables', vars, found)
    call json%get('entry:'//compound_name//':sources:variables', vars, found)
    !call json%get('entry.tavg-h2m-hxy-u.sources.variables', vars, found)

    do i = 1, size(vars)
        write(*,*) trim(vars(i))
    end do
    ! Get the list of keys under "entry"
    !call json%get_keys(entry, keys, n)

    !print *, 'Keys found in "entry":'
    !do i = 1, n
        !print *, trim(keys(i))
    !end do

    ! Clean up
    call json%destroy()

end program read_entry_keys
