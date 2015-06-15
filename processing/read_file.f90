module read_file
	
	implicit none
	
	integer simu_type, maxit, nsteps, nprint
	real(8) :: tol, dt, damp
	real(8) :: materialprops(5), gravity(3)
	integer :: nsd, nen, nn, nel, no_bc1, no_bc2
	integer, allocatable :: connect(:,:)
	real(8), allocatable :: coords(:,:), bc1(:,:), bc2(:,:)
	
	save
	
contains
	subroutine read_input(unitnum,filename,simu_type, maxit, nsteps, nprint, tol, dt, damp, materialprops, gravity)
		implicit none
		
		integer, intent(in) :: unitnum
		character(len=*), intent(in) :: filename
	
		character(100) :: text
		character(1) :: flag=':'
		integer :: i, j, k, l, ios=0
		real(8) :: temp(15)
	
		integer, intent(out) :: simu_type, maxit, nsteps, nprint
		real(8), intent(out) :: tol, dt, damp, materialprops(5), gravity(3)
	
		open(unit=unitnum,file=filename)
		i=0
		do while(ios==0)
			read(10,'(a)',IOSTAT=ios) text
			j=index(text,flag)
			l=0
			if (j /= 0) then
				i=i+1
				do k=j+1,len_trim(text)
					if (text(k:k) /= ' ') then
						l=l+1
					endif
				end do
				read(text(j+1:j+1+l),*) temp(i)
			end if	
		end do
	
		simu_type=int(temp(1))
		tol=temp(2)
		maxit=int(temp(3))
		nsteps=int(temp(4))
		dt=temp(5)
		nprint=int(temp(6))
		damp=temp(7)
		materialprops(:)=temp(8:12)
		gravity(:)=temp(13:15)
	
		close(10)
	end subroutine read_input
	
	subroutine read_mesh(nsd,nn,nel,nen,coords,connect,bc1,bc2)
		implicit none
		
		integer, intent(out) :: nsd, nen, nn, nel
		integer, allocatable, intent(out) :: connect(:,:)
		real(8), allocatable, intent(out) :: coords(:,:), bc1(:,:), bc2(:,:)
	
		integer :: no_bc1, no_bc2, i
	
		open(10,file='coords.txt')
		read(10,*) nsd, nn
		allocate(coords(3,nn)) 
		do i=1,nn
			read(10,*) coords(:,i)
		end do
		close(10)
	
		open(10,file='connect.txt')
		read(10,*) nel, nen
		allocate(connect(nen,nel))
		do i=1,nel
			read(10,*) connect(:,i)
		end do
		close(10)
	
		open(10,file='bc1.txt')
		read(10,*) no_bc1
		allocate(bc1(3,no_bc1))
		do i=1,no_bc1
			read(10,*) bc1(:,i)
		end do
		close(10)
	
		open(10,file='bc2.txt')
		read(10,*) no_bc2
		allocate(bc2(5,no_bc2))
		do i=1,no_bc2
			read(10,*) bc2(:,i)
		end do
	    close(10)
	
	end subroutine read_mesh
	
end module read_file
	
	