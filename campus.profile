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
  campus_create_demo_menus();
  campus_create_demo_menu_links();
  module_enable(array('campus_blocks_setting'));
  campus_update_block_class() ;
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

function campus_update_block_class() {
	if (!module_exists('block_class')) { 
		return;
	}
	db_insert('block_class')->fields(array('module' => 'menu', 'delta' => 'menu-footer-menu', 'css_class' => 'footer-menu'))->execute();
	db_insert('block_class')->fields(array('module' => 'menu', 'delta' => 'menu-fresh-dashboard', 'css_class' => 'menu-dashboard'))->execute();
	db_insert('block_class')->fields(array('module' => 'block', 'delta' => 'menu-footer-menu', 'css_class' => ''))->execute();
	db_insert('block_class')->fields(array('module' => 'block', 'delta' => '', 'css_class' => ''))->execute();
	db_insert('block_class')->fields(array('module' => 'menu_block', 'delta' => '11', 'css_class' => 'block-menu-social-network-link'))->execute();
	db_insert('block_class')->fields(array('module' => 'menu_block', 'delta' => '3', 'css_class' => 'sidebar-menu'))->execute();
	db_insert('block_class')->fields(array('module' => 'menu_block', 'delta' => '5', 'css_class' => 'sidebar-menu'))->execute();
	db_insert('block_class')->fields(array('module' => 'menu_block', 'delta' => '7', 'css_class' => 'menu-dashboard'))->execute();
	db_insert('block_class')->fields(array('module' => 'vc_admin', 'delta' => 'dashboard_user_tool', 'css_class' => 'user-links'))->execute();
	db_insert('block_class')->fields(array('module' => 'vc_content', 'delta' => 'current_campus_menu', 'css_class' => 'block-current-campus'))->execute();
}

/**
 * Creates menu items.
 */
function campus_create_demo_menus() {
  $menus = array();

  // Exported menu: main-menu.
  $menus['main-menu'] = array(
    'menu_name' => 'main-menu',
    'title' => 'Main menu',
    'description' => 'The <em>Main</em> menu is used on many sites to show the major sections of the site, often in a top navigation bar.',
  );
  // Exported menu: menu-footer-menu.
  $menus['menu-footer-menu'] = array(
    'menu_name' => 'menu-footer-menu',
    'title' => 'Footer menu',
    'description' => '',
  );
  // Exported menu: menu-fresh-dashboard.
  $menus['menu-fresh-dashboard'] = array(
    'menu_name' => 'menu-fresh-dashboard',
    'title' => 'Fresh Dashboard',
    'description' => '',
  );
  // Exported menu: menu-homepage-news-box.
  $menus['menu-homepage-news-box'] = array(
    'menu_name' => 'menu-homepage-news-box',
    'title' => 'Homepage news box',
    'description' => '',
  );
  // Exported menu: menu-influncer-campus.
  $menus['menu-influncer-campus'] = array(
    'menu_name' => 'menu-influncer-campus',
    'title' => 'Influncer Campus',
    'description' => '',
  );
  // Exported menu: menu-new-influencer.
  $menus['menu-new-influencer'] = array(
    'menu_name' => 'menu-new-influencer',
    'title' => 'New Influencer',
    'description' => 'Display 2 link "Im new" and "Be a Influencer" at campus site header block',
  );
  // Exported menu: menu-social-network-link.
  $menus['menu-social-network-link'] = array(
    'menu_name' => 'menu-social-network-link',
    'title' => 'Social network link',
    'description' => '',
  );
  
  foreach($menus as $menu){
		menu_save($menu);
    watchdog('menu', 'Add menu %name', aray('%name' => $menu['menu_name']));
	}
}

/**
 * Creates menu link items.
 */
function campus_create_demo_menu_links() {
  $menu_links = array();

  // Exported menu link: menu-footer-menu:<front>
  $menu_links['menu-footer-menu:<front>'] = array(
    'menu_name' => 'menu-footer-menu',
    'link_path' => '<front>',
    'router_path' => '',
    'link_title' => 'Ps. Ashley & Jane',
    'options' => array(
      'attributes' => array(
        'title' => '',
      ),
    ),
    'module' => 'menu',
    'hidden' => '0',
    'external' => '1',
    'has_children' => '0',
    'expanded' => '0',
    'weight' => '-50',
    'parent_path' => 'about',
  );
  // Exported menu link: menu-footer-menu:about-ash-jane
  $menu_links['menu-footer-menu:about-ash-jane'] = array(
    'menu_name' => 'menu-footer-menu',
    'link_path' => 'about-ash-jane',
    'router_path' => 'about-ash-jane',
    'link_title' => 'Ps Ashley & Jane',
    'options' => array(
      'attributes' => array(
        'title' => '',
      ),
    ),
    'module' => 'menu',
    'hidden' => '0',
    'external' => '0',
    'has_children' => '0',
    'expanded' => '0',
    'weight' => '-50',
    'parent_path' => '<front>',
  );
  // Exported menu link: menu-footer-menu:campus
  $menu_links['menu-footer-menu:campus'] = array(
    'menu_name' => 'menu-footer-menu',
    'link_path' => 'campus',
    'router_path' => 'campus',
    'link_title' => 'Ministries',
    'options' => array(
      'attributes' => array(
        'title' => '',
      ),
    ),
    'module' => 'menu',
    'hidden' => '0',
    'external' => '0',
    'has_children' => '0',
    'expanded' => '0',
    'weight' => '-49',
    'parent_path' => '<front>',
  );
  // Exported menu link: menu-footer-menu:concierge
  $menu_links['menu-footer-menu:concierge'] = array(
    'menu_name' => 'menu-footer-menu',
    'link_path' => 'concierge',
    'router_path' => 'concierge ',
    'link_title' => 'Concierge',
    'options' => array(
      'attributes' => array(
        'title' => '',
      ),
    ),
    'module' => 'menu',
    'hidden' => '0',
    'external' => '0',
    'has_children' => '0',
    'expanded' => '0',
    'weight' => '0',
    'parent_path' => '<front>',
  );
  // Exported menu link: menu-footer-menu:devotions_online
  $menu_links['menu-footer-menu:devotions_online'] = array(
    'menu_name' => 'menu-footer-menu',
    'link_path' => 'devotions_online',
    'router_path' => 'devotions_online',
    'link_title' => 'Devotions Online',
    'options' => array(
      'attributes' => array(
        'title' => '',
      ),
    ),
    'module' => 'menu',
    'hidden' => '0',
    'external' => '0',
    'has_children' => '0',
    'expanded' => '0',
    'weight' => '-49',
    'parent_path' => '<front>',
  );
  // Exported menu link: menu-footer-menu:events
  $menu_links['menu-footer-menu:events'] = array(
    'menu_name' => 'menu-footer-menu',
    'link_path' => 'events',
    'router_path' => 'events',
    'link_title' => 'Events',
    'options' => array(
      'attributes' => array(
        'title' => '',
      ),
    ),
    'module' => 'menu',
    'hidden' => '0',
    'external' => '0',
    'has_children' => '0',
    'expanded' => '0',
    'weight' => '-48',
    'parent_path' => '<front>',
  );
  // Exported menu link: menu-footer-menu:group
  $menu_links['menu-footer-menu:group'] = array(
    'menu_name' => 'menu-footer-menu',
    'link_path' => 'group',
    'router_path' => 'group',
    'link_title' => 'Groups',
    'options' => array(
      'attributes' => array(
        'title' => '',
      ),
    ),
    'module' => 'menu',
    'hidden' => '0',
    'external' => '0',
    'has_children' => '0',
    'expanded' => '0',
    'weight' => '-50',
    'parent_path' => '<front>',
  );
  // Exported menu link: menu-footer-menu:influencers_live
  $menu_links['menu-footer-menu:influencers_live'] = array(
    'menu_name' => 'menu-footer-menu',
    'link_path' => 'influencers_live',
    'router_path' => 'influencers_live',
    'link_title' => 'Influencers Live',
    'options' => array(
      'attributes' => array(
        'title' => '',
      ),
    ),
    'module' => 'menu',
    'hidden' => '0',
    'external' => '0',
    'has_children' => '0',
    'expanded' => '1',
    'weight' => '-50',
    'parent_path' => '<front>',
  );
  // Exported menu link: menu-footer-menu:location
  $menu_links['menu-footer-menu:location'] = array(
    'menu_name' => 'menu-footer-menu',
    'link_path' => 'location',
    'router_path' => 'location',
    'link_title' => 'Location',
    'options' => array(
      'attributes' => array(
        'title' => '',
      ),
    ),
    'module' => 'menu',
    'hidden' => '0',
    'external' => '0',
    'has_children' => '0',
    'expanded' => '0',
    'weight' => '-50',
    'parent_path' => '<front>',
  );
  // Exported menu link: menu-footer-menu:podcasts
  $menu_links['menu-footer-menu:podcasts'] = array(
    'menu_name' => 'menu-footer-menu',
    'link_path' => 'podcasts',
    'router_path' => 'podcasts',
    'link_title' => 'Podcasts',
    'options' => array(
      'attributes' => array(
        'title' => '',
      ),
    ),
    'module' => 'menu',
    'hidden' => '0',
    'external' => '0',
    'has_children' => '0',
    'expanded' => '0',
    'weight' => '-50',
    'parent_path' => '<front>',
  );
  // Exported menu link: menu-footer-menu:services
  $menu_links['menu-footer-menu:services'] = array(
    'menu_name' => 'menu-footer-menu',
    'link_path' => 'services',
    'router_path' => 'services',
    'link_title' => 'Services',
    'options' => array(
      'attributes' => array(
        'title' => '',
      ),
    ),
    'module' => 'menu',
    'hidden' => '0',
    'external' => '0',
    'has_children' => '0',
    'expanded' => '0',
    'weight' => '-49',
    'parent_path' => '<front>',
  );
  // Exported menu link: menu-footer-menu:store
  $menu_links['menu-footer-menu:store'] = array(
    'menu_name' => 'menu-footer-menu',
    'link_path' => 'store',
    'router_path' => 'store',
    'link_title' => 'Store',
    'options' => array(
      'attributes' => array(
        'title' => '',
      ),
    ),
    'module' => 'menu',
    'hidden' => '0',
    'external' => '0',
    'has_children' => '0',
    'expanded' => '0',
    'weight' => '-48',
    'parent_path' => '<front>',
  );
  // Exported menu link: menu-footer-menu:team
  $menu_links['menu-footer-menu:team'] = array(
    'menu_name' => 'menu-footer-menu',
    'link_path' => 'team',
    'router_path' => 'team',
    'link_title' => 'Team',
    'options' => array(
      'attributes' => array(
        'title' => '',
      ),
    ),
    'module' => 'menu',
    'hidden' => '0',
    'external' => '0',
    'has_children' => '0',
    'expanded' => '0',
    'weight' => '-48',
    'parent_path' => 'about',
  );
  // Exported menu link: menu-footer-menu:vision
  $menu_links['menu-footer-menu:vision'] = array(
    'menu_name' => 'menu-footer-menu',
    'link_path' => 'vision',
    'router_path' => 'vision',
    'link_title' => 'Vision',
    'options' => array(
      'attributes' => array(
        'title' => '',
      ),
    ),
    'module' => 'menu',
    'hidden' => '0',
    'external' => '0',
    'has_children' => '0',
    'expanded' => '0',
    'weight' => '-49',
    'parent_path' => 'about',
  );
  // Exported menu link: menu-fresh-dashboard:vc/contents
  $menu_links['menu-fresh-dashboard:vc/contents'] = array(
    'menu_name' => 'menu-fresh-dashboard',
    'link_path' => 'vc/contents',
    'router_path' => 'vc/contents',
    'link_title' => 'Content',
    'options' => array(
      'attributes' => array(
        'title' => '',
      ),
    ),
    'module' => 'menu',
    'hidden' => '0',
    'external' => '0',
    'has_children' => '0',
    'expanded' => '0',
    'weight' => '-49',
  );
  // Exported menu link: menu-fresh-dashboard:vc/dashboard
  $menu_links['menu-fresh-dashboard:vc/dashboard'] = array(
    'menu_name' => 'menu-fresh-dashboard',
    'link_path' => 'vc/dashboard',
    'router_path' => 'vc/dashboard',
    'link_title' => 'Dashboard',
    'options' => array(
      'attributes' => array(
        'title' => '',
      ),
    ),
    'module' => 'menu',
    'hidden' => '0',
    'external' => '0',
    'has_children' => '0',
    'expanded' => '0',
    'weight' => '-50',
  );
  // Exported menu link: menu-fresh-dashboard:vc/site_settings
  $menu_links['menu-fresh-dashboard:vc/site_settings'] = array(
    'menu_name' => 'menu-fresh-dashboard',
    'link_path' => 'vc/site_settings',
    'router_path' => 'vc/site_settings',
    'link_title' => 'Site settings',
    'options' => array(
      'attributes' => array(
        'title' => '',
      ),
    ),
    'module' => 'menu',
    'hidden' => '0',
    'external' => '0',
    'has_children' => '0',
    'expanded' => '0',
    'weight' => '-48',
  );
  // Exported menu link: menu-homepage-news-box:devotions_online
  $menu_links['menu-homepage-news-box:devotions_online'] = array(
    'menu_name' => 'menu-homepage-news-box',
    'link_path' => 'devotions_online',
    'router_path' => 'devotions_online',
    'link_title' => 'Paradise TV Online',
    'options' => array(
      'attributes' => array(
        'title' => '',
      ),
    ),
    'module' => 'menu',
    'hidden' => '0',
    'external' => '0',
    'has_children' => '0',
    'expanded' => '0',
    'weight' => '-48',
  );
  // Exported menu link: menu-homepage-news-box:give
  $menu_links['menu-homepage-news-box:give'] = array(
    'menu_name' => 'menu-homepage-news-box',
    'link_path' => 'give',
    'router_path' => 'give',
    'link_title' => 'Onling Giving',
    'options' => array(
      'attributes' => array(
        'title' => '',
      ),
    ),
    'module' => 'menu',
    'hidden' => '0',
    'external' => '0',
    'has_children' => '0',
    'expanded' => '0',
    'weight' => '-49',
  );
  // Exported menu link: menu-homepage-news-box:podcasts
  $menu_links['menu-homepage-news-box:podcasts'] = array(
    'menu_name' => 'menu-homepage-news-box',
    'link_path' => 'podcasts',
    'router_path' => 'podcasts',
    'link_title' => 'Podcast Download',
    'options' => array(
      'attributes' => array(
        'title' => '',
      ),
    ),
    'module' => 'menu',
    'hidden' => '0',
    'external' => '0',
    'has_children' => '0',
    'expanded' => '0',
    'weight' => '-47',
  );
  // Exported menu link: menu-homepage-news-box:store
  $menu_links['menu-homepage-news-box:store'] = array(
    'menu_name' => 'menu-homepage-news-box',
    'link_path' => 'store',
    'router_path' => 'store',
    'link_title' => 'Paradise Album',
    'options' => array(
      'attributes' => array(
        'title' => '',
      ),
    ),
    'module' => 'menu',
    'hidden' => '0',
    'external' => '0',
    'has_children' => '0',
    'expanded' => '0',
    'weight' => '-50',
  );
  // Exported menu link: menu-influncer-campus:<front>
  $menu_links['menu-influncer-campus:<front>'] = array(
    'menu_name' => 'menu-influncer-campus',
    'link_path' => '<front>',
    'router_path' => '',
    'link_title' => 'Australia',
    'options' => array(
      'attributes' => array(
        'title' => '',
      ),
    ),
    'module' => 'menu',
    'hidden' => '0',
    'external' => '1',
    'has_children' => '1',
    'expanded' => '1',
    'weight' => '-50',
  );
  // Exported menu link: menu-new-influencer:i-am-new
  $menu_links['menu-new-influencer:i-am-new'] = array(
    'menu_name' => 'menu-new-influencer',
    'link_path' => 'i-am-new',
    'router_path' => 'i-am-new',
    'link_title' => 'I\'m new',
    'options' => array(
      'attributes' => array(
        'title' => '',
      ),
    ),
    'module' => 'menu',
    'hidden' => '0',
    'external' => '0',
    'has_children' => '0',
    'expanded' => '0',
    'weight' => '-50',
  );
  // Exported menu link: menu-new-influencer:influencer
  $menu_links['menu-new-influencer:influencer'] = array(
    'menu_name' => 'menu-new-influencer',
    'link_path' => 'influencer',
    'router_path' => 'influencer',
    'link_title' => 'Be an Influencer',
    'options' => array(
      'attributes' => array(
        'title' => '',
      ),
    ),
    'module' => 'menu',
    'hidden' => '0',
    'external' => '0',
    'has_children' => '0',
    'expanded' => '0',
    'weight' => '-49',
  );
  // Exported menu link: menu-social-network-link:<front>
  $menu_links['menu-social-network-link:<front>'] = array(
    'menu_name' => 'menu-social-network-link',
    'link_path' => '<front>',
    'router_path' => '',
    'link_title' => 'Facebook',
    'options' => array(
      'attributes' => array(
        'title' => '',
      ),
    ),
    'module' => 'menu',
    'hidden' => '0',
    'external' => '1',
    'has_children' => '0',
    'expanded' => '0',
    'weight' => '-50',
  );
  // Exported menu link: menu-social-network-link:http://vimeo.com/
  $menu_links['menu-social-network-link:http://vimeo.com/'] = array(
    'menu_name' => 'menu-social-network-link',
    'link_path' => 'http://vimeo.com/',
    'router_path' => '',
    'link_title' => 'Vimeo',
    'options' => array(
      'attributes' => array(
        'title' => '',
      ),
    ),
    'module' => 'menu',
    'hidden' => '0',
    'external' => '1',
    'has_children' => '0',
    'expanded' => '0',
    'weight' => '-48',
  );
  // Exported menu link: menu-social-network-link:rss.xml
  $menu_links['menu-social-network-link:rss.xml'] = array(
    'menu_name' => 'menu-social-network-link',
    'link_path' => 'rss.xml',
    'router_path' => 'rss.xml',
    'link_title' => 'Rss',
    'options' => array(
      'attributes' => array(
        'title' => '',
      ),
    ),
    'module' => 'menu',
    'hidden' => '0',
    'external' => '0',
    'has_children' => '0',
    'expanded' => '0',
    'weight' => '-47',
  );

  foreach($menu_links as $menu_link){
		menu_link_save($menu_link);
    watchdog('menu', 'Add menu link %name', aray('%name' => $menu_link['menu_name']));
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