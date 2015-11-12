;
begin
;
; Check a grib file for variables and dimensions.  Softlink the grib file
; to this directory, being sure that the extension is ".grb".
;
;  grb_file = addfile("/scratch/frd/collande/meso.AWPDWFE24.tm00.grb","r")
;  grb_file = addfile("../postprd/wrfprs_all_d01.00.grib","r")
  grb_file = addfile("/glade/p/ral/jnt/MMET/2012062812/OUTPUT/NAMps_12km_3km_v0.9/DOMAINS/2012062812/postprd/nmbtwo_d01_03.tm00.grib","r")
;
  names = getfilevarnames(grb_file)  ; Get the variable names in the
  print(names)                       ; GRIB file and print them out.
;
  do i = 0, dimsizes( names ) - 1
    print("Variable Name: " + names(i))
    dims = getfilevardims(grb_file,names(i))
    sizes = filevardimsizes(grb_file,names(i))
    print(dimsizes(sizes) + " Dimensions:")
    if(.not.any(ismissing(dims))) then
      do j = 0, dimsizes(dims) -1
        print( j + ") " + dims(j) + ": " + sizes(j))
      end do  
    end if
    atts = getfilevaratts(grb_file,names(i))
    if(.not.any(ismissing(atts))) then
      do k = 0, dimsizes(atts) -1
        print(atts(k) + ": " +grb_file->$names(i)$@$atts(k)$)
      end do
    end if
    delete(atts)
    delete(dims)
    delete(sizes)
    print("")
  end do
  atts = getfilevaratts(grb_file,names(0)) ; Get the variable attributes and
  dims = getfilevardims(grb_file,names(0)) ; dimension names from the GRIB
  print(atts)                              ; file and print them out.
  print(dims)
;
;  smpl = grb_file->lv_ISBL2(:)

;  do i = 0, 36
;   print(i)
;   print(smpl(i))
;  end do

;levels = grb_file->lv_ISBL2(:)
;print(levels)

;lat = grb_file->g3_lat_0(:,:)
;lon = grb_file->g3_lon_1(:,:)
;lat = grb_file->gridlat_252(:,:)
;lon = grb_file->gridlon_252(:,:)
;p = grb_file->lv_ISBL3(:)
;print(lat)
;print(lon)
;print(p)
;
end
