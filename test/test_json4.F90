program read_json_keys
    use json_module
    implicit none

    type(json_file) :: json_f
    type(json_core) :: json
    type(json_value), pointer :: entry_ptr => null()
    type(json_value), pointer :: element_ptr => null()
    character(len=:), allocatable :: key
    integer :: i, num_keys

    ! 1. Initialize core and load file using json_file
    call json%initialize()
    call json_f%load_file('../recipes/variable_mapping_NorESM3.json')
    if (json_f%failed()) stop "Error loading file"

    ! 2. Get the pointer to the 'entry' object from the loaded file
    ! json_f%p is the public pointer to the root of the JSON structure
    call json%get_child(json_f, 'entry', entry_ptr)

    if (associated(entry_ptr)) then
        ! 3. Get the number of keys inside 'entry'
        call json%info(entry_ptr, n_children=num_keys)
        
        print *, "Found ", num_keys, " keys in 'entry':"
        
        ! 4. Iterate through children using the json_core object
        do i = 1, num_keys
            call json%get_child(entry_ptr, i, element_ptr)
            !call json%get_name(element_ptr, key)
            call json%get(element_ptr, key)
            print *, "Key ", i, ": ", key
        end do
    else
        print *, "Error: 'entry' object not found."
    end if

    ! 5. Cleanup
    call json_f%destroy()
end program read_json_keys

