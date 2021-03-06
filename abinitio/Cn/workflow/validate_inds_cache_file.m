function is_valid = validate_inds_cache_file(workflow_fcachename)
    
varlist = who(matfile(workflow_fcachename));
is_valid = any(strcmp(varlist,'R_theta_ijs')) && ...
any(strcmp(varlist,'Ris_tilde')) && ...
any(strcmp(varlist,'cijs_inds')) && ...
any(strcmp(varlist,'n_theta'));
   
end