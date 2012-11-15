<?php
/**
 * @file
 * Enables modules and site configuration for a campus site installation.
 */

/**
 * Implements hook_form_FORM_ID_alter() for install_configure_form().
 *
 * Allows the profile to alter the site configuration form.
 */
function campus_form_install_configure_form_alter(&$form, $form_state) {
  // Pre-populate the site name with the server name.
  $form['site_information']['site_name']['#default_value'] = $_SERVER['SERVER_NAME'];
}



/**
 * Implements hook_install_tasks().
 */
function campus_install_tasks($install_state) {
  return array(
    'campus_profile_setup' => array(),
  );
}

/**
 * Installer task callback.
 */
function campus_profile_setup() {
  campus_update_fpp();
}

/**
 * Insert value fieldable pane panel
 */
function campus_update_fpp() {
  
}