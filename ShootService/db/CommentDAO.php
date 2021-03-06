<?php
/**
* 
*/
class CommentDAO extends BaseDAO
{
	public function query($currentUser_id, $shoot_id, $comment_id) {
		if ($comment_id) {
			$query = "SELECT comment.*, like_comment.user_id as if_cur_user_like_it from comment LEFT JOIN like_comment on comment.id = like_comment.comment_id and like_comment.user_id = $currentUser_id where comment.id = $comment_id";
		} else {
			$query = "SELECT comment.*, like_comment.user_id as if_cur_user_like_it from comment LEFT JOIN like_comment on comment.id = like_comment.comment_id and like_comment.user_id = $currentUser_id where shoot_id = $shoot_id";
		}

		$result = $this->db_conn->query($query);

		/* create one master array of the records */
		$comments = array();
		if(mysql_num_rows($result)) {
			while($comment = mysql_fetch_assoc($result)) {
				$comments[] = $this->getStructuredComment($comment, $currentUser_id);
			}
		}
		return $comments;
	}
	
	public function delete($user_id, $id) {
		$query = "UPDATE comment SET deleted = 1 WHERE id = $id AND user_id = $user_id";
		$this->db_conn->query($query);
	}
	
	private function getCommentById($comment_id) {
		$query = "SELECT * from comment where id = $comment_id";

		$result = $this->db_conn->query($query);

		if(mysql_num_rows($result)) {
			while($comment = mysql_fetch_assoc($result)) {
				return $this->getStructuredComment($comment, null);
			}
		}
		return null;
	}
	
	private function getStructuredComment($comment, $currentUser_id) {
		
		$shoot = array('id' => $comment['shoot_id']);
		$user = array('id' => $comment['user_id']);
		return array('shoot' => $shoot, 
		             'user' => $user, 
					 'id' => $comment['id'], 
		             'content' => $comment['content'],
					 'x' => $comment['x'],
					 'y' => $comment['y'],
					 'time' => $comment['time'],
					 'like_count' => $comment['like_count'],
					 'if_cur_user_like_it' => ($currentUser_id == null ? null : $comment['if_cur_user_like_it'] == $currentUser_id),
					 'deleted' => $comment['deleted']
				     );
	}
	
	public function create($comment) {
		$query = 'INSERT INTO comment (shoot_id, user_id, content, x, y) VALUES ('
			    . $comment->get_shoot_id() . ',' 
			    . $comment->get_user_id() . ',' 
				. ($comment->get_content() == NULL ? 'NULL' : ('\'' . mysql_real_escape_string($comment->get_content()) . '\'')) . ',' 
				. $comment->get_x() . ','
				. $comment->get_y() . ')';
		$id = $this->db_conn->insert($query);
		return $this->getCommentById($id);
	}
	
	public function setUserLikeComment($user_id, $comment_id) {
		$query = "INSERT INTO like_comment (comment_id, user_id) VALUES($comment_id,$user_id)";	
		$this->db_conn->query($query);
		$query = "UPDATE comment SET like_count =  like_count + 1 WHERE id = $comment_id";
		$this->db_conn->query($query);	
	}
	
	public function setUserUnlikeComment($user_id, $comment_id) {
		$query = "DELETE FROM like_comment WHERE user_id = $user_id AND comment_id = $comment_id";
		$this->db_conn->query($query);
		$query = "UPDATE comment SET like_count =  like_count - 1 WHERE id = $comment_id";
		$this->db_conn->query($query);
	}
}

?>