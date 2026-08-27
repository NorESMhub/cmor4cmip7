program list_entry_keys
    use json_module
    implicit none

    type(json_file)              :: json
    type(json_core)              :: core
    type(json_value), pointer    :: entry_p, child
    character(len=:), allocatable :: key
    logical                      :: found
    integer                      :: i, n_children

    ! Initialize the JSON module
    call json%initialize()

    ! Load the JSON file (adjust filename as needed)
    call json%load_file('../recipes/variable_mapping_NorESM3.json')
    if (json%failed()) then
        print *, 'Error loading JSON file.'
        stop
    end if

    ! Get a pointer to the "entry" object
    call json%get('entry', entry_p, found)
    if (.not. found) then
        print *, 'Key "entry" not found in the JSON file.'
        stop
    end if

    ! Retrieve the core from the json_file object
    call json%get_core(core)

    ! Verify that entry_p points to a JSON object
    !if (.not. core%is_object(entry_p)) then
        !print *, '"entry" is not a JSON object.'
        !stop
    !end if

    ! Count the number of key‑value pairs inside the entry object
    call core%info(entry_p, n_children=n_children)

    ! Loop over all children and print their keys
    do i = 1, n_children
        write(*,*) 'i:',i
        call core%get_child(entry_p, i, child)
            call core%get(child, key)
                print *, trim(key)
        if (associated(child)) then
            !call core%get_child(child, key)
            call core%get(child, key)
                print *, trim(key)
            if (allocated(key)) then
                print *, trim(key)
                deallocate(key)
            end if
        end if
    end do

    ! Clean up
    call json%destroy()

end program list_entry_keys
