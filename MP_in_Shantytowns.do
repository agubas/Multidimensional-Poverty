clear all
use "C:\Users\admin\Desktop\Agustin\ENDC\Base Interna ENDC 2015 individuales.dta", clear

keep  /*educacion*/ a6_asiste a2_edad a8_niveleducacional ///
/*trabajo y seguridad social*/rec_sub a9_sitlab a13_cotiza a11_ocupacion b11_subsidio ///
  /*vivienda*/ c1_dor_total c3_ind_hacin a14_perstotal c9a_mat_techo C9A_TECHO_rec c9b_mat_piso C9B_PISO_rec c9c_mat_muros C9C_MUROS_rec c9d_ind_mat c4_sum_agua c6_sum_bagno /// 
  /*otros*/  a4_sexo nenc ncamp nombre_jefe folio region a2_edad_casen sum_pobreza ///
  /*salud*/b5_consult
	
gen edad=a2_edad if a2_edad<99
rename a4_sexo sexo
drop a2_edad 
rename a2_edad_casen edadcasen

/*Indicador Hogar*/
	/*Folio Jefe Hogar*/
	gen nombre_jefe2=nombre_jefe+"blanco"
	gen foliojh=.
	replace foliojh=folio if nombre_jefe2!=" blanco"
	drop nombre_jefe2
	
/*Id Hogar*/
	replace foliojh=foliojh[_n-1] if foliojh==.
	
/*Indices por individuo*/

/*EDUCACION*/
  
	/*Acceso a la educacion I*/ /* al menos
un integrante de 6 a 26 años tiene una condición permanente y/o de larga
duración y no asiste a un establecimiento educacional. 
*/
gen niveleduc=.
replace niveleduc=a8_niveleducacional if a8_niveleducacional<99
	
 gen asistaux=.
 replace asistaux=1 if a6_asiste>0 & a6_asiste!=99
 replace asistaux=0 if a6_asiste==0
 gen deduc_1=.
 replace deduc_1=0 if asistaux==0 & 3<edad & 19>edad & (niveleduc!=4 | niveleduc!=6 | niveleduc!=7| niveleduc!=8| niveleduc!=9 )
 replace deduc_1=1 if edad<19 & edad>3 & (asistaux==1 | niveleduc==4 | niveleduc==6 | niveleduc==7| niveleduc==8| niveleduc==9)  
 
	
	/*Escolaridad Basica*/ 
	
egen edadmax=max(edad), by(foliojh)
gen bascomp=.
replace bascomp=0 if niveleduc==0 |niveleduc==1 |  niveleduc==3
replace bascomp=1 if niveleduc==2  | niveleduc==4| niveleduc==5| niveleduc==6| niveleduc==7| niveleduc==8| niveleduc==9

gen mediacomp=.
replace mediacomp=0 if niveleduc==0 | niveleduc==1 | niveleduc==2  | niveleduc==3 | niveleduc==5
replace mediacomp=1 if niveleduc==4  | niveleduc==6 | niveleduc==7| niveleduc==8| niveleduc==9

gen supcomp=.
replace supcomp=0 if niveleduc==0 | niveleduc==1  |niveleduc==2  |  niveleduc==3  | niveleduc==4| niveleduc==5  | niveleduc==7| niveleduc==9  
replace supcomp=1 if niveleduc==6 | niveleduc==8
/*Escolaridad Basica*/
gen deduc_2b=.
replace deduc_2b=0 if edad>18 & bascomp==0
replace deduc_2b=1 if (edad>18 & bascomp==1)| edadmax<19

/*Escolaridad Media*/
gen deduc_2m=.
replace deduc_2m=0 if edad>18 & mediacomp==0
replace deduc_2m=1 if (edad>18 & mediacomp==1) | edadmax<19

/*Rezago Escolar SUBESTIMADO*/ 
	gen deduc_r=1
	replace deduc_r=0 if (mediacomp==0 & edad>18 & asistaux==1) | (bascomp==0 & edad>14 & asistaux==1) | (a6_asiste==1 & edad>3 & asistaux==1) | (a6_asiste==2 & edad>3 & asistaux==1)
	replace deduc_r=. if niveleduc==. | edad==. | a6_asiste==.
/*SALUD*/ //b5_consult
gen consultorio=.
replace consultorio=b5_consult if b5_consult!=99
gen consxpers=consultorio/a14_perstotal
replace consxpers=. if consxpers>1	
drop b5_consult

/*TRABAJO Y SEGURIDAD SOCIAL*/

	/*Ocupacion*/
	gen desocupado=.
	replace desocupado=0 if a9_sitlab<10
	replace desocupado=1 if a9_sitlab==2
	
	gen dtrab_1=.
	replace dtrab_1=0 if edad>18 & desocupado==1
	replace dtrab_1=0 if edad<19 & desocupado==1 & mediacomp==1
	replace dtrab_1=1 if (edad>18 & desocupado==0) 
	
	/*Seguridad Social*/
	gen cotiza=.
	replace cotiza=1 if a13_cotiza==1
	replace cotiza=0 if a13_cotiza==2
	gen ocupado=.
	replace ocupado=0 if a9_sitlab<10
	replace ocupado=1 if a9_sitlab==3 // se considera ocupado solo a aquellos que trabajan remuneradamente
	gen ctapropiaeducsup=.
	replace ctapropiaeducsup=1 if a11_ocupacion==1 & supcomp==1
	replace ctapropiaeducsup=0 if a11_ocupacion!=1 | supcomp==0
	
	gen dtrab_2=.
	replace dtrab_2=0 if ocupado==1 & cotiza==0 & ctapropiaeducsup!=1 & edad>15
	replace dtrab_2=1 if ocupado==1 & cotiza==1
	replace dtrab_2=1 if ocupado==1 & cotiza==0 & ctapropiaeducsup==1
	replace dtrab_2=1 if ocupado==1 & cotiza==0 & ctapropiaeducsup==0 & edad<16 //desocupados
	
	/*Jubilacion*/
	gen jubil=0
	replace jubil=1 if sexo==1 & edad>59
	replace jubil=1 if sexo==2 & edad>64
	replace jubil=. if sexo==. | edad==.
	
	egen mrec_sub=mean(rec_sub) 
	replace rec_sub=mrec_sub if rec_sub==. & folio==foliojh // rempalzo de nulos por media
	replace rec_sub=rec_sub[_n-1] if rec_sub==.
	
	gen dtrab_3=.
	replace dtrab_3=0 if jubil==1 & rec_sub==0 
	replace dtrab_3=1 if jubil==1 & rec_sub>0 & rec_sub!=.
	
/*Vivienda*/

	/*Hacinamiento*/
	gen persxdorm=(a14_perstotal/c1_dor_total)
	replace persxdorm=. if a14_perstotal==. | c1_dor_total==.
		
	gen dviv_1=.
	replace dviv_1=0 if persxdorm>=2.5 & persxdorm!=.
	replace dviv_1=1 if persxdorm<2.5 & persxdorm!=.
		
	/*Estado de la Vivienda*/
	gen dviv_2=.	
	replace dviv_2=1 if (C9A_TECHO_rec==1 | C9A_TECHO_rec==2)	& (C9B_PISO_rec==1 | C9B_PISO_rec==2) & (C9C_MUROS_rec==1 | C9C_MUROS_rec==2)																							
	replace dviv_2=0 if C9A_TECHO_rec==3 | C9B_PISO_rec==3 |  C9C_MUROS_rec==3
	
	
	/*Servicios Basicos*/
	gen agua=.
	replace agua=c4_sum_agua if c4_sum_agua!=99
	
	gen dviv_3u_1=.
	replace dviv_3u_1=1 if agua==1  | agua==5
	replace dviv_3u_1=0 if agua==2 | agua==3 | agua==4 | agua==7
	
	gen dviv_3r_1=.
	replace dviv_3r_1=1 if agua==1 | agua==2 |agua==3| agua==4| agua==5
	replace dviv_3r_1=o if agua==7
	
	gen bagno=.
	replace bagno=c6_sum_bagno if c6_sum_bagno!=99
	
	gen dviv_3_2=.
	replace dviv_3_2=1 if bagno==1 | bagno==2
	replace dviv_3_2=0 if bagno==3 | bagno==4 | bagno==5 | bagno==6 | bagno==7 | bagno==8| bagno==9| bagno==10| bagno==11 // Baños comunitarios se considera que no cumple
	
	gen dviv_3u=. // criterios urbanos
	replace dviv_3u=1 if dviv_3u_1==1 & dviv_3_2==1
	replace dviv_3u=0 if dviv_3u_1==0 | dviv_3_2==0
	
	gen dviv_3r=. //criterios rurales
	replace dviv_3r=1 if dviv_3r_1==1 & dviv_3_2==1
	replace dviv_3r=0 if dviv_3r_1==0 | dviv_3_2==0
	
/*Entorno y Redes*/


	
	
/*Indices por hogar*/

/*Relleno Total de Personas*/

replace a14_perstotal=a14_perstotal[_n-1] if a14_perstotal==.

	/*EDUCACION*/
  
	/*Acceso a la educacion*/
	egen ndeduc_1=total(deduc_1==0), by (foliojh)
	
	gen deduch_1=.
	replace deduch_1=0 if ndeduc_1>0 & ndeduc!=.
	replace deduch_1=1 if ndeduc_1==0
	
	/*Escolaridad*/
	egen ndeduc_2b=total(deduc_2b==0), by (foliojh)

	gen deduch_2b=.
	replace deduch_2b=0 if ndeduc_2b>0 & ndeduc_2b!=.
	replace deduch_2b=1 if ndeduc_2b==0
	
	egen ndeduc_2m=total(deduc_2m==0), by(foliojh)
	
	gen deduch_2m=.
	replace deduch_2m=0 if ndeduc_2m>0 & ndeduc_2m!=.
	replace deduch_2m=1 if ndeduc_2m==0
	
	/*Rezago Escolar*/ 
	egen ndeduc_r=total(deduc_r==0), by(foliojh)
	
	gen deduch_r=0 if ndeduc_r>0 & ndeduc_r!=.
	replace deduch_r=1 if ndeduc_r==0
	/*SALUD*/
	
	/*TRABAJO Y SEGURIDAD SOCIAL*/

	/*Ocupacion*/
	egen ndtrab_1=total(dtrab_1==0), by(foliojh)
	
	gen dtrabh_1=.
	replace dtrabh_1=0 if ndtrab_1>0 & ndtrab_1!=.
	replace dtrabh_1=1 if ndtrab_1==0
	
	/*Seguridad Social*/
	egen ndtrab_2=total(dtrab_2==0), by(foliojh)
	
	gen dtrabh_2=.
	replace dtrabh_2=0 if ndtrab_2>0 & ndtrab_2!=.
	replace dtrabh_2=1 if ndtrab_2==0
		
	/*Jubilacion*/
	egen ndtrab_3=total(dtrab_3==0), by(foliojh)

	gen dtrabh_3=.
	replace dtrabh_3=0 if ndtrab_3>0 & ndtrab_3!=.
	replace dtrabh_3=1 if ndtrab_3==0
	
	/*VIVIENDA*/ //no se pasan los nulos al hogar
	/*Hacinamiento*/
	//replace dviv_1=dviv_1[_n-1] if dviv_1==.
	/*Estado de la Vivienda*/ 
	//replace dviv_2=dviv_2[_n-1] if dviv_2==.
	/*Servicios Basicos*/
	//replace dviv_3u=dviv_3u[_n-1] if dviv_3u==.
//	replace dviv_3r=dviv_3r[_n-1] if dviv_3r==.
	
	/*ENTORNO Y REDES*/
	
	
	
	/*INDICE*/ // dviv_1 dviv_2 dviv_3u deduch_1 deduch_2m dtrabh_1 dtrabh_2 dtrabh_3
	gen idviv_1=.
	replace idviv_1=abs(dviv_1-1) 
	gen idviv_2=.
	replace idviv_2=abs(dviv_2-1)
	gen idviv_3u=.
	replace idviv_3u=abs(dviv_3u-1)
	gen ideduch_1=.
	replace ideduch_1=abs(deduch_1-1)
	gen ideduch_2m=.
	replace ideduch_2m=abs(deduch_2m-1)
	gen ideduch_r=.
	replace ideduch_r=abs(deduch_r-1)
	gen idtrabh_1=.
	replace idtrabh_1=abs(dtrabh_1-1)
	gen idtrabh_2=.
	replace idtrabh_2=abs(dtrabh_2-1)
	gen idtrabh_3=.
	replace idtrabh_3=abs(dtrabh_3-1)
	
	/*Relleno indices de vivienda*/
	replace idviv_1=idviv_1[_n-1] if idviv_1==.
	replace idviv_2=idviv_2[_n-1] if idviv_2==.
	replace idviv_3=idviv_3[_n-1] if idviv_3==.
	
	/*Privaciones*/
gen priv=.
replace priv= (0.167)*ideduch_1 + (0.167)*ideduch_2m + (0.111)*idtrabh_1 + (0.111)*idtrabh_2 + (0.111)*idtrabh_3 + (0.111)*idviv_1 + (0.111)*idviv_2 + (0.111)*idviv_3u
 
gen pobrem25=.
replace pobrem25=1 if priv > 0.25
replace pobrem25=0 if priv <= 0.25
replace pobrem25=. if priv==.

gen pobrem33=.
replace pobrem33=1 if priv > 0.33
replace pobrem33=0 if priv <= 0.33
replace pobrem33=. if priv==.

gen pobrem375=.
replace pobrem375=1 if priv > 0.375
replace pobrem375=0 if priv <= 0.375
replace pobrem375=. if priv==.

mpi d1(ideduch_1 ideduch_2m) d2(idtrabh_1 idtrabh_2 idtrabh_3) d3(idviv_1 idviv_2 idviv_3u) , cutoff(0.25)
mpi d1(ideduch_1 ideduch_2m) d2(idtrabh_1 idtrabh_2 idtrabh_3) d3(idviv_1 idviv_2 idviv_3u) , cutoff(0.33)
mpi d1(ideduch_1 ideduch_2m) d2(idtrabh_1 idtrabh_2 idtrabh_3) d3(idviv_1 idviv_2 idviv_3u) , cutoff(0.375)
putexcel a11=matrix(r(by_ind),names) using contribuciones_indicadores_ind_375, replace

mpi d1(ideduch_1 ideduch_2m) d2(idtrabh_1 idtrabh_2 idtrabh_3) d3(idviv_1 idviv_2 idviv_3u) , cutoff(0.25) by(region)
mpi d1(ideduch_1 ideduch_2m) d2(idtrabh_1 idtrabh_2 idtrabh_3) d3(idviv_1 idviv_2 idviv_3u) , cutoff(0.33) by(region)
mpi d1(ideduch_1 ideduch_2m) d2(idtrabh_1 idtrabh_2 idtrabh_3) d3(idviv_1 idviv_2 idviv_3u) , cutoff(0.375) by(region)
putexcel a6=matrix(r(by_mpi),names) using mpi_region_ind_3carencias, replace

gen pobrei=sum_pobreza
replace pobrei=pobrei[_n-1] if pobrei==.

gen pobre375=.
replace pobre375=0 if pobrem375==0 & pobrei==2	
replace pobre375=1 if pobrem375==0 & pobrei==1
replace pobre375=2 if pobrem375==1 & pobrei==2
replace pobre375=3 if pobrem375==1 & pobrei==1

label define indpob 0 "No Pobre" 1 "Solo Pobre por Ingreso" 2 "Solo Pobre Multidimensional" 3 "Pobre en Ambos Indicadores"
label values pobre375 indpob
