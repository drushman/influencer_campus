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
    $values = array('bundle' => 'fieldable_panels_pane', 
        'title'=> $item[0], 
        'admin_title' => $item[1], 
        'category' => $item[2], 
        'reusable' => TRUE, 
    );
    $fpp = fieldable_panels_panes_create($values);
    $fpp = fieldable_panels_panes_save($fpp);
    $fpp->field_page_title['und'][0]['value'] = $item[6];
    $fpp->field_page_description['und'][0]['value'] = $item[3];
    $value=$item[4]; //Youtube video ID

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
	  //$file = file_uri_to_object('youtube://v/' . $value, TRUE);
	  //$provider = media_internet_get_provider('http://www.youtube.com/watch?v=hUBYkFubCIk');
	  //$file = $provider->save();
	//dsm($file);
	  //$file = file_save($file);
    }
    $fpp->field_page_video['und'][0]['fid'] = $file->fid;
    
	if (empty($item[5])) {
	  continue;
	}
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
    $fpp = fieldable_panels_panes_save($fpp);
  }
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