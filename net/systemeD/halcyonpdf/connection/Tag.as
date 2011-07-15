package net.systemeD.halcyonpdf.connection {

	/*	Changes for Halcyon/PDF:
		- setters removed
	*/

    public class Tag {
        private var entity:Entity;
        private var _key:String;
        private var _value:String;

        public function Tag(entity:Entity, key:String, value:String) {
            this.entity = entity;
            entity.addEventListener(Connection.TAG_CHANGED, tagChanged, false, 0, true);
            this._key = key;
            this._value = value;
        }

        public function get key():String { return _key; }
        public function get value():String { return _value; }

        private function tagChanged(event:TagEvent):void {
            if ( event.key == _key )
                _value = event.newValue;
        }
    }


}

