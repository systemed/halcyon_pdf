package net.systemeD.halcyonpdf.connection {

	/*	Changes for Halcyon/PDF:
		- all methods referencing actions deleted
	*/

    public class Relation extends Entity {
        private var members:Array;
		public static var entity_type:String = 'relation';

        public function Relation(connection:Connection, id:Number, version:uint, tags:Object, loaded:Boolean, members:Array, uid:Number = NaN, timestamp:String = null) {
            super(connection, id, version, tags, loaded, uid, timestamp);
            this.members = members;
			for each (var member:RelationMember in members)
			    member.entity.addParent(this);
        }

        public function update(version:uint, tags:Object, loaded:Boolean, parentsLoaded:Boolean, members:Array, uid:Number = NaN, timestamp:String = null):void {
			var member:RelationMember;
			for each (member in this.members)
			    member.entity.removeParent(this);

			updateEntityProperties(version,tags,loaded,parentsLoaded,uid,timestamp);
			this.members=members;
			for each (member in members)
			    member.entity.addParent(this);
		}
		
        public function get length():uint {
            return members.length;
        }

		public function get memberEntities():Array {
			var list:Array=[];
			for (var index:uint = 0; index < members.length; index++) {
				var e:Entity=members[index].entity;
				if (list.indexOf(e)==-1) list.push(e);
			}
			return list;
		}

        public function findEntityMemberIndex(entity:Entity):int {
            for (var index:uint = 0; index < members.length; index++) {
                var member:RelationMember = members[index];
                if ( member.entity == entity )
                    return index;
            }
            return -1;
        }

        public function findEntityMemberIndexes(entity:Entity):Array {
            var indexes:Array = [];
            for (var index:uint = 0; index < members.length; index++) {
                var member:RelationMember = members[index];
                if ( member.entity == entity )
                    indexes.push(index);
            }
            return indexes;
        }
        
        public function getMember(index:uint):RelationMember {
            return members[index];
        }

		public function findMembersByRole(role:String, entityType:Class=null):Array {
			var a:Array=[];
            for (var index:uint = 0; index < members.length; index++) {
                if (members[index].role==role && (!entityType || members[index].entity is entityType)) { a.push(members[index].entity); }
            }
			return a;
		}

		public function hasMemberInRole(entity:Entity,role:String):Boolean {
            for (var index:uint = 0; index < members.length; index++) {
				if (members[index].role==role && members[index].entity == entity) { return true; }
			}
			return false;
		}
		
		public override function nullify():void {
			nullifyEntity();
			members=[];
		}
		
		internal override function isEmpty():Boolean {
			return (deleted || (members.length==0));
		}

        public override function getDescription():String {
            var desc:String = "";
            var relTags:Object = getTagsHash();
            if ( relTags["type"] ) {
                desc = relTags["type"];
                if ( relTags[desc] )
                    desc += " " + relTags[desc];
            }
            if ( relTags["ref"] )
                desc += " " + relTags["ref"];
            if ( relTags["name"] )
                desc += " " + relTags["name"];
            return desc;
        }

		public override function getType():String {
			return 'relation';
		}
		
		public override function toString():String {
            return "Relation("+id+"@"+version+"): "+members.length+" members "+getTagList();
        }

    }

}
