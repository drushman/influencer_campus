<?php
/**
 * Implementation of hook_profile_form_alter().
 */
function campus_form_alter(&$form, $form_state, $form_id) {
  // Add an additional submit handler. 
  if ($form_id == 'install_configure_form' || $form_id == 'node_admin_content') {
    $form['site_information']['site_name']['#default_value'] = $_SERVER['SERVER_NAME'];
    $form['#submit'][] = 'campus_configure_form_submit';
  }
}

/**
 * Custom form submit handler for configuration form.
 *
 * Drops all data from existing database, imports database dump, and restores
 * values entered into configuration form.
 */
function campus_configure_form_submit($form, &$form_state) {
  $account = user_load(1);
  user_save($account, array('roles' => $account->roles + array( 4 => 'administrator' )));
}

/**
 * Implements hook_install_tasks().
 */
function campus_install_tasks($install_state) {
  return array(
    'campus_profile_setup' => array(),
    'campus_settings_form' => array(
      'display_name' => st('Setup Campus settings'),
      'type' => 'form',
    ),
  );
}

/**
 * Installer task callback.
 */
function campus_profile_setup() {
  campus_update_fpp();
  //campus_update_menu();
  module_enable(array('campus_blocks_setting'));
  campus_update_block_class() ;
  campus_update_menu();
}

/**
 * Insert value fieldable pane panel
 */
function campus_update_fpp() {
  $filename = 'profiles/campus/demo_content/fieldable_pane_panel.txt';
	$contents = trim(file_get_contents($filename));
	if (!$contents) {
    return null;
  }
	$rows = explode("\n", $contents);
	$ids = array();
  $rows = array_slice($rows, 1); 
  foreach($rows as $row){
    $item = explode("|", $row);
    $values = array(
      'bundle' => 'fieldable_panels_pane', 
      'title'=> $item[0], 
      'admin_title' => $item[1], 
      'category' => $item[2], 
      'reusable' => TRUE, 
    );
    $fpp = fieldable_panels_panes_create($values);
    $fpp = fieldable_panels_panes_save($fpp);
    $fpp->field_page_title['und'][0]['value'] = $item[6];
    $fpp->field_page_description['und'][0]['value'] = $item[3];
    $fpp->field_page_description['und'][0]['format'] = 'full_html';
  	$value = $item[4]; //Youtube video ID
  	if (!empty($value)) {
  		$fid = db_query('SELECT fid FROM {file_managed} WHERE uri = :uri', array(':uri' => 'youtube://v/' . $value))->fetchField();
  		if (!empty($fid)) {
  		  $file = file_load($fid);
  		} 
  		else {
  		  $file = new stdClass();
  		  $file->uid = 1;
  		  $file->filename = $value;
  		  $file->uri = 'youtube://v/' . $value;
  		  $file->filemime = 'video/youtube';
  		  $file->type = 'video';
  		  $file->status = 1;
  		  $file = file_save($file);
  		}
  		$fpp->field_page_video['und'][0]['fid'] = $file->fid;
  	}
    
    if (!empty($item[5])) {
      $file_img = new StdClass();
  		$file_img->uid = 1;
  		$file_img->uri = DRUPAL_ROOT.'/profiles/campus/demo_content/'.$item[5];
  		$file_img->filemime = file_get_mimetype($file->uri);
  		$file_img->status = 1;
  		$name = $item[5];
  		$dest = file_default_scheme() . '://'.$name;
  		$file_img = file_copy($file_img, $dest);
  		$file_img = file_save($file_img);
  		$fpp->field_page_banner[LANGUAGE_NONE][0] = (array)$file_img;
    }
    $fpp = fieldable_panels_panes_save($fpp);
  }
  
  $invalid_fpp = array( 2, 4, 5);
  fieldable_panels_panes_delete_multiple($invalid_fpp);
}

function campus_update_block_class() {
	if (!module_exists('block_class')) { 
		return;
	}
	db_insert('block_class')->fields(array('module' => 'menu', 'delta' => 'menu-footer-menu', 'css_class' => 'footer-menu'))->execute();
	db_insert('block_class')->fields(array('module' => 'menu', 'delta' => 'menu-fresh-dashboard', 'css_class' => 'menu-dashboard'))->execute();
//	db_insert('block_class')->fields(array('module' => 'block', 'delta' => 'menu-footer-menu', 'css_class' => ''))->execute();
	db_insert('block_class')->fields(array('module' => 'block', 'delta' => '2', 'css_class' => 'navigation-menu'))->execute();
	db_insert('block_class')->fields(array('module' => 'block', 'delta' => '11', 'css_class' => 'block-menu-social-network-link'))->execute();
	db_insert('block_class')->fields(array('module' => 'menu_block', 'delta' => '5', 'css_class' => 'sidebar-menu'))->execute();
  db_insert('block_class')->fields(array('module' => 'menu_block', 'delta' => '3', 'css_class' => 'sidebar-menu'))->execute();
	db_insert('block_class')->fields(array('module' => 'block', 'delta' => '7', 'css_class' => 'menu-dashboard'))->execute();
	db_insert('block_class')->fields(array('module' => 'vc_admin', 'delta' => 'dashboard_user_tool', 'css_class' => 'user-links'))->execute();
	db_insert('block_class')->fields(array('module' => 'vc_content', 'delta' => 'current_campus_menu', 'css_class' => 'block-current-campus'))->execute();
}

function campus_update_menu() {
  $menu = array(
    'menu_name' => 'menu-fresh-dashboard',
    'title' => 'Fresh Dashboard',
    'description' => 'Left menu in Vietcoop Dashboard pages.',
  );   
//  menu_save($menu);       
  watchdog('menu', 'Add menu link %name', array('%name' => $menu['menu_name']));  
  watchdog('menu', 'Check Dashboard menu %name', array('%name' => drupal_lookup_path('source', 'vc/dashboard')));
	$file->uid = 1;
	$file->uri = drupal_get_path('module', 'vc_menu_default') . "/include/{$menu['menu_name']}.txt";
	$file->filemime = file_get_mimetype($file->uri);
	$file->status = 1;
	$dest = file_default_scheme() . '://'.$menu['menu_name'];
	$file = file_copy($file, $dest);
	$file = file_save($file);
	
	$option = array(
			'create_content' => 0,
			'link_to_content' => 0,
			'remove_menu_items' => 1,
			'node_type' => '',
			'node_body' => '',
			'node_author' => 0,
			'node_status' => 0,
			'node_alias' => 0,
	);
	
	module_load_include('inc', 'menu_import', 'includes/import');
	
	$menu = menu_import_parse_menu_from_file($file->uri, $menu['menu_name'], $option );	
	menu_import_save_menu($menu, $option);
  file_delete($file);
}

function campus_settings_form() {
  $form = array();
  
  $form['campus_settings'] = array(
    '#type' => 'fieldset',
    '#title' => st('Setting your campus client website.'),
  );
  
  $form['campus_settings']['campus_type'] = array(
    '#type' => 'radios',
    '#title' => st('Choice campus type:'),
    '#default_value' => variable_get('campus_type', 'campus'),
    '#options' => array(
      'global' => st('Global site'),
      'campus' => st('Campus site'),
    ),
  );
  
  $form['campus_settings']['campus_information'] = array(
    '#type' => 'fieldset',
    '#title' => st('Campus site information'),
    '#states' => array(
      'visible' => array(
         ':input[name="campus_type"]' => array('value' => 'campus'),            
      )               
    ),
  );
  
  $form['campus_settings']['campus_information']['campus_name'] = array(
    '#type' => 'textfield',
    '#title' => st('Campus name'),
    '#default_value' => variable_get('campus_name', 'Campus'),
    '#required' => TRUE
  );
  
  $form['campus_settings']['campus_information']['campus_address'] = array(
    '#type' => 'textfield',
    '#title' => st('Campus address'),
    '#default_value' => variable_get('campus_address', ''),
  );
  
  $form['campus_settings']['campus_information']['campus_country'] = array(
    '#type' => 'textfield',
    '#title' => st('Campus Country'),
    '#default_value' => variable_get('campus_country', 'Australia'),
    '#required' => TRUE,
  );
  
  $form['campus_settings']['campus_information']['campus_services'] = array(
    '#type' => 'textfield',
    '#title' => st('Campus services'),
    '#default_value' => variable_get('campus_services', ''),
    '#description' => t('Campus services time. Example: 9:30 AM, 11:30 AM, 5:30 PM, 7:30 PM'),
  );
  
  $form['submit'] = array(
    '#type' => 'submit',
    '#value' => st('Continue'),
  );
  return $form;
}

function campus_settings_form_submit($form, &$form_state) {
  $values = $form_state['values'];
  
  if ($values['campus_type']) {
    variable_set('campus_name', $values['campus_name']); 
    variable_set('campus_country', $values['campus_country']);
    if ($values['campus_address']) {
      variable_set('campus_address', $values['campus_address']);
    }
    if ($values['campus_services']) {
      variable_set('campus_services', $values['campus_services']); 
    }
  } else {
    variable_set('campus_name', 'GLOBAL');
  }  
}
