import http from 'k6/http';
import { sleep } from 'k6';


// vus Usuarios
// duration segundos de duração
export const options = {
	vus: 10,
	duration: '30s',
};

export default function() {
	http.get('http://localhost:5200/Auth');
	sleep(1);
}