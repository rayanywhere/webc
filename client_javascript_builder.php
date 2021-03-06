<?php
require_once __DIR__ . '/builder.class.php';
require_once __DIR__ . '/3party/smarty/Smarty.class.php';

class ClientJavascriptBuilder extends Builder {

	public function build() {
		$parser = null;
		foreach ($this->_sourceFiles as $sourceFile) {
			if($parser == null) {
				$parser = $this->getParser($sourceFile);
			}
			else {
				$tmpParser = $this->getParser($sourceFile);
				$parser->merge($tmpParser);
			}
		}

		$smarty = $this->getSmarty();
		$smarty->assign('structs', $parser->getStructs());
		$content = $smarty->fetch(__DIR__ . '/client/javascript/WebcObject.tpl');
		$this->saveFile('/WebcObject.js', $content);

		$smarty = $this->getSmarty();
		$smarty->assign('interfaces', $parser->getInterfaces());
		$content = $smarty->fetch(__DIR__ . '/client/javascript/WebcClient.tpl');
		$this->saveFile('/WebcClient.js', $content);
	}
}

if($argc < 3)
	die("usage: php " . $argv[0] . " <source_folder> <target_folder>\n");

try{
	$builder = new ClientJavascriptBuilder($argv[1], $argv[2]);
	$builder->build();
}
catch(Exception $e){
	die("compilation failed, reason:" . $e->getMessage() . "\n");
}
