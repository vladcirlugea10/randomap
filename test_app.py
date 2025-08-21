from app import app
import unittest

class BasicTestCase(unittest.TestCase):

    def test_home(self):
        """Test the home page loads correctly."""
        # Create a test client
        tester = app.test_client(self)

        # Make a GET request to the home page
        response = tester.get('/', content_type='html/text')

        # Assert that the status code is 200 (OK)
        self.assertEqual(response.status_code, 200)

        # Assert that the response data contains our app's title
        self.assertIn(b'Random Earth Teleporter', response.data)

if __name__ == '__main__':
    unittest.main()