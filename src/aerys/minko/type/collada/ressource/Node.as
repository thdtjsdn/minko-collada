package aerys.minko.type.collada.ressource
{
	import aerys.minko.ns.minko_collada;
	import aerys.minko.scene.node.IScene;
	import aerys.minko.scene.node.group.TransformGroup;
	import aerys.minko.scene.node.skeleton.Joint;
	import aerys.minko.type.collada.Document;
	import aerys.minko.type.collada.helper.TransformParser;
	import aerys.minko.type.collada.instance.IInstance;
	import aerys.minko.type.collada.instance.InstanceController;
	import aerys.minko.type.collada.instance.InstanceGeometry;
	import aerys.minko.type.collada.instance.InstanceNode;
	import aerys.minko.type.math.Matrix4x4;

	use namespace minko_collada;
	
	public class Node implements IRessource
	{
		private static const NS	: Namespace = 
			new Namespace("http://www.collada.org/2005/11/COLLADASchema");
		
		private var _document	: Document;
		
		private var _id			: String;
		private var _sid		: String;
		private var _name		: String;
		private var _transform	: Matrix4x4;
		private var _type		: String;
		
		private var _childs		: Vector.<IInstance>;
		
		public function get id()		: String				{ return _id; }
		public function get sid()		: String				{ return _sid; }
		public function get name()		: String				{ return _name; }
		public function get transform()	: Matrix4x4				{ return _transform; }
		public function get type()		: String				{ return _type; }
		public function get childs()	: Vector.<IInstance>	{ return _childs; }
		
		public static function fillStoreFromXML(xmlDocument	: XML,
												document	: Document, 
												store		: Object) : void
		{
			var xmlNodeLibrary	: XML		= xmlDocument..NS::library_nodes[0];
			if (xmlNodeLibrary == null)
				return;
			
			var xmlNodes		: XMLList	= xmlNodeLibrary.NS::node;
			
			for each (var xmlNode : XML in xmlNodes)
			{
				var node : Node = new Node(xmlNode, document);
				store[node.id] = node;
			}
		}
		
		public function Node(xmlNode : XML, document : Document) 
		{
			_document	= document;
			
			_id			= xmlNode.@id;
			_sid		= xmlNode.@sid;
			_name		= xmlNode.@name;
			_transform	= TransformParser.parseTransform(xmlNode);
			_type		= xmlNode.@type;
			_childs		= new Vector.<IInstance>();
			
			for each (var child : XML in xmlNode.children())
			{
				
				var localName : String = child.localName();
				
				if (localName == 'node')
					_childs.push(document.delegateRessourceCreation(child));
					
				else if (localName == 'instance_camera')
						0; // do nothing
					
				else if (localName == 'instance_controller')
					_childs.push(InstanceController.createFromXML(document, child));
				
				else if (localName == 'instance_geometry')
					_childs.push(InstanceGeometry.createFromXML(document, child));
				
				else if (localName == 'instance_light')
					0; // do nothing
				
				else if (localName == 'instance_node')
					_childs.push(InstanceNode.createFromXML(document, child));
			}
		}
		
		public function getChildAt(index : uint) : IInstance
		{
			return _childs[index];
		}
		
		public function createInstance() : IInstance				
		{
			return new InstanceNode(_document, _id); 
		}
		
		/**
		 * to be fixed
		 * child.toScene will instanciate every time a new minko object
		 * 
		 * what happens for a scene with many times the same mesh?
		 * 
		 * @return 
		 */		
		public function toTransformGroup() : TransformGroup
		{
			var tf : TransformGroup = new TransformGroup();
			for each (var child : IInstance in _childs)
				tf.addChild(child.toScene());
			return tf;
		}
		
		public function toJoint() : Joint
		{
			var joint : Joint = new Joint();
			for each (var child : IInstance in _childs)
			{
				var minkoChild : IScene;
				
				if (child is InstanceNode)
					minkoChild = Node(child.ressource).toJoint();
				else
					minkoChild = child.toScene();
				
				joint.addChild(minkoChild);
			}
			return joint;
		}
	}
}